class Posting < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :unit
  belongs_to :posting_recurrence

  has_many :tote_items
  has_many :users, through: :tote_items

  has_many :delivery_postings
  has_many :deliveries, through: :delivery_postings

  validates :description, :quantity_available, :price, :delivery_date, :commitment_zone_start, presence: true
  validates :quantity_available, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  validates :units_per_case, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  #the weird syntax below is due to some serious gotchas having to do with how booleans are stores or something? I have no idea. See here:
  #http://stackoverflow.com/questions/10506575/rails-database-defaults-and-model-validation-for-boolean-fields
  validates :live, inclusion: { in: [true, false] }
  validate :delivery_date_not_sunday, :commitment_zone_start_must_be_before_delivery_date, :commission_is_set
  before_create :delivery_date_must_be_after_today

  validates_presence_of :user, :product, :unit  

  def get_creditor
    return user.get_creditor
  end

  def get_producer_net_unit
    producer_net_unit = price - commission_per_unit - ToteItemsController.helpers.get_payment_processor_fee_unit(price)
    return producer_net_unit.round(2)
  end

  def get_producer_net_case
    
    if units_per_case.nil? || units_per_case < 2
      return nil
    end

    producer_net_case = (get_producer_net_unit * units_per_case).round(2)

    return producer_net_case

  end

  def inbound_order_value_producer_net

    if state?(:CLOSED)
      num_units = num_units_filled
    else
      num_units = inbound_num_units_ordered
    end
    
    return (num_units * get_producer_net_unit).round(2)

  end

  def commission_per_unit
    commission_factor = get_commission_factor
    commission_per_unit = (price * commission_factor).round(2)
    return commission_per_unit
  end

  def get_commission_factor

    commission_factors = ProducerProductUnitCommission.where(user: user, product: product, unit: unit)

    #TODO: the following line is superfluous, as far as i can tell. however, i get a sqlliteexception without it. strange!
    #i don't think there's anything magical about calling .to_a. when creating this i was able to get things to succeed
    #as intended when i used a variety of reading methods instead of .to_a
    commission_factors.to_a

    if commission_factors.order(:created_at).last.nil?
      return 0
    else
      return commission_factors.order(:created_at).last.commission
    end    

  end

  def order_minimum_retail

    if order_minimum_producer_net.nil?
      return 0
    end

    return (order_minimum_producer_net / (1.0 - (0.035 + get_commission_factor))).round(2)

  end

  def additional_retail_amount_necessary_to_send_order
    return [order_minimum_retail - inbound_order_value_retail, 0].max
  end

  def inbound_order_value_retail
    
    if state?(:CLOSED)
      num_units = num_units_filled
    else
      num_units = inbound_num_units_ordered
    end
    
    return (num_units * price).round(2)

  end

  #OPEN means open for customers to place orders. but that's somewhat confusing because if late_adds_allowed then customer can place order even in the COMMITMENTZONE
  #so really all OPEN means right now is the period of time before commitment_zone_start. the meaning isn't even yet comingled/intermingled iwth the concept of 'live'.
  #yuck. it is what it is. we'll clean it up eventually
  #COMMITMENTZONE is the period of time between commitment_zone_start and when product is CLOSED
  #CLOSED is either when the posting is canceled or filled. we don't even have 'canceled' built in. eventually we'll put a control for the admin (or producer, i guess) to
  #cancel the posting. if/when you want to 'cancel' a posting we'll probably need to implement it. it will depend on if there are outstanding orders or not.
  def self.states
    {OPEN: 0, COMMITMENTZONE: 1, CLOSED: 2}
  end

  def state?(state_key)
    return state == Posting.states[state_key]
  end

  def transition(input)
    
    new_state = state

    case state


    when Posting.states[:OPEN]
      case input
      when :commitment_zone_started

        if Time.zone.now >= commitment_zone_start
          new_state = Posting.states[:COMMITMENTZONE]

          #'late adds' are a customer authorizing a tote item in between commitment zone start and delivery date.
          #(FYI by default late adds are not allowed)
          #if late adds are not allowed, here - when transitioning the posting from OPEN to COMMITMENTZONE - we need
          #to give all non-authorized tote items the boot...transition them from ADDED to REMOVED. otherwise it will
          #happen that user will add a tote item before the CZS but not auth it. they'll wait a day or two, then come
          #back to their tote (now in the commitment zone) and just authorize it. when customer does this an email goes
          #out at the top of the next hour to the producer telling them they have more order. this is confusing if they
          #aren't expecting it. so we just boot the customer here so they can't authorize late.
          if !late_adds_allowed
            update(live: false)
            tote_items.where(state: ToteItem.states[:ADDED]).each do |tote_item|
              tote_item.transition(:system_removed)
            end            
          end

          tote_items.where(state: ToteItem.states[:AUTHORIZED]).each do |tote_item|
            tote_item.transition(:commitment_zone_started)
          end

          if !posting_recurrence.nil? && posting_recurrence.on
            posting_recurrence.recur
          end

        end        
      
      end


    when Posting.states[:COMMITMENTZONE]      
      case input
      when :filled
        new_state = Posting.states[:CLOSED]        
      end


    when Posting.states[:CLOSED]

    end

    if new_state != state
      update(state: new_state)
    end

  end

  def fill(quantity)

    quantity_remaining = quantity
    quantity_filled = 0
    quantity_not_filled = 0
    tote_items_filled = []
    tote_items_not_filled = []
    partially_filled_tote_items = []

    #fill in FIFO order. partially fill if need be.
    first_committed_tote_item = get_first_committed_tote_item
    while first_committed_tote_item
      if quantity_remaining > 0
        quantity_to_fill = [first_committed_tote_item.quantity, quantity_remaining].min
        quantity_remaining = quantity_remaining - quantity_to_fill
        quantity_filled = quantity_filled + quantity_to_fill
        first_committed_tote_item.transition(:tote_item_filled, {quantity_filled: quantity_to_fill})
        tote_items_filled << first_committed_tote_item

        if first_committed_tote_item.partially_filled?
          partially_filled_tote_items << first_committed_tote_item
          first_committed_tote_item.reload          
        end

      else        
        first_committed_tote_item.transition(:tote_item_not_filled)                
        tote_items_not_filled << first_committed_tote_item
      end

      quantity_not_filled += first_committed_tote_item.quantity_not_filled      
      first_committed_tote_item = get_first_committed_tote_item

    end

    transition(:filled)

    return {
      quantity_filled: quantity_filled,
      quantity_not_filled: quantity_not_filled,
      quantity_remaining: quantity_remaining,
      tote_items_filled: tote_items_filled,
      tote_items_not_filled: tote_items_not_filled,
      partially_filled_tote_items: partially_filled_tote_items
    }

  end

  def requirements_met_to_send_order?

    #packing minimum met?(at least one unit (or 1 case if cases are in effect))
    if !packing_minimum_met?
      return false
    end

    if !order_minimum_met?
      return false
    end

    return true
    
  end

  def order_minimum_met?

    if order_minimum_producer_net.nil?
      return true
    end

    return inbound_order_value_producer_net > order_minimum_producer_net

  end

  def packing_minimum_met?
    if units_per_case.nil? || units_per_case < 2
      return total_quantity_authorized_or_committed > 0
    else
      return total_quantity_authorized_or_committed >= units_per_case
    end
  end

  def inbound_num_units_ordered

    if units_per_case.nil? || units_per_case < 2
      unit_count = total_quantity_authorized_or_committed
    else
      unit_count = inbound_num_cases_ordered * units_per_case
    end

    return unit_count
    
  end

  def num_units_filled
    return tote_items.where(state: ToteItem.states[:FILLED]).sum(:quantity_filled)
  end

  def inbound_num_cases_ordered
    
    if units_per_case.nil? || units_per_case < 1
      return nil
    end
    
    return total_quantity_authorized_or_committed / units_per_case    

  end

  def self.product_name_from_posting_id(id)
  	posting = Posting.find(id)
  	if posting != nil
  		product = Product.find(posting.id)
  		if product != nil
  			product.name
  		end
  	end
  end

  def additional_units_required_to_fill_items_case(tote_item, include_this_item = true)

    if tote_item.state?(:ADDED)

      quantity_all_authorized_or_committed = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).sum(:quantity)      
      quantity_added_through = tote_items.where(user_id: tote_item.user_id, state: ToteItem.states[:ADDED]).where(include_this_item ? "created_at <= ?" : "created_at < ?", tote_item.created_at).sum(:quantity)

      queue_quantity_through_item = quantity_all_authorized_or_committed + quantity_added_through
      queue_quantity_after_item = include_this_item ? tote_items.where(user_id: tote_item.user_id, state: ToteItem.states[:ADDED]).where("created_at > ?", tote_item.created_at).sum(:quantity) : 0

    elsif tote_item.state?(:AUTHORIZED) || tote_item.state?(:COMMITTED)      

      quantity_authorized_or_committed_after = include_this_item ? tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where("authorized_at > ?", tote_item.authorized_at).sum(:quantity) : 0
      quantity_all_added = include_this_item ? tote_items.where(user_id: tote_item.user_id, state: ToteItem.states[:ADDED]).sum(:quantity) : 0      

      queue_quantity_through_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where(include_this_item ? "authorized_at <= ?" : "authorized_at < ?", tote_item.authorized_at).sum(:quantity)
      queue_quantity_after_item = quantity_authorized_or_committed_after + quantity_all_added

    else
      return 0
    end

    additional_units_required_to_fill_items_case = units_per_case - (queue_quantity_through_item % units_per_case) - queue_quantity_after_item
    additional_units_required_to_fill_items_case = [0, additional_units_required_to_fill_items_case].max
    #this next line really is needed. it's for the case where the case boundary is hit dead on. in this case additional_units_required_to_fill_items_case == units_per_case prior to this line
    additional_units_required_to_fill_items_case = additional_units_required_to_fill_items_case % units_per_case

    return additional_units_required_to_fill_items_case

  end
  
  def total_quantity_authorized_or_committed(tis = nil)

    if tis.nil?
      tis = tote_items
    end
    
    return authorized_or_committed_tote_items(tis).sum(:quantity)    

  end

  def authorized_or_committed_tote_items(tis = nil)

    if tis.nil?
      tis = tote_items
    end

    return tis.where("state = ? or state = ?", ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED])

  end

  def total_quantity_ordered
    #{AUTHORIZED: 1, COMMITTED: 2, FILLED: 4
    #we also want NOTFILLED because after the delivery date the farmer might want to review past postings and
    #see how much quantity was ordered. although he might also want to review historical sales. we'll change that
    #down the road. for now we're going to add NOTFILLED because the name of the method is 'ordered' and anything
    #that ended up in state NOTFILLED was at one point 'ordered'.
    ordered_tote_items = tote_items.where("state = ? or state = ? or state = ? or state = ?",
      ToteItem.states[:AUTHORIZED],
      ToteItem.states[:COMMITTED],
      ToteItem.states[:FILLED],
      ToteItem.states[:NOTFILLED])

    return ordered_tote_items.sum(:quantity)

  end

  private

    def get_first_committed_tote_item
      return tote_items.where(state: ToteItem.states[:COMMITTED]).order("tote_items.id").first    
    end  
    
    def delivery_date_not_sunday
      if delivery_date != nil && delivery_date.sunday?
        errors.add(:delivery_date, "Delivery date can not be Sunday")
      end
    end

    def delivery_date_must_be_after_today      

      if delivery_date.nil? || delivery_date <= Time.zone.today
        errors.add(:delivery_date, "Delivery date must be after today")
        return false
      end

      return true

    end

    def commitment_zone_start_must_be_before_delivery_date

      if delivery_date.nil?
        errors.add(:delivery_date, "Delivery date must be specified")
        return
      end

      if delivery_date.nil? || commitment_zone_start.nil? || commitment_zone_start > delivery_date
        errors.add(:commitment_zone_start, "Commitment zone must start prior to delivery date")
      end

    end

    def commission_is_set

      commission = ProducerProductUnitCommission.where(user: user, product: product, unit: unit)

      if commission.count == 0
        errors.add(:commission_is_set, "Commission must be set for producer/product/unit")
        return false
      end

      return true

    end

end
