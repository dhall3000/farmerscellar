class Posting < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :unit
  belongs_to :posting_recurrence

  has_many :tote_items
  has_many :users, through: :tote_items

  has_many :delivery_postings
  has_many :deliveries, through: :delivery_postings

  has_many :creditor_order_postings
  has_many :creditor_orders, through: :creditor_order_postings

  has_many :posting_uploads
  has_many :uploads, through: :posting_uploads

  #OPEN means open for customers to place orders. the meaning isn't even yet comingled/intermingled iwth the concept of 'live'.
  #yuck. it is what it is. we'll clean it up eventually
  #COMMITMENTZONE is the period of time between order_cutoff and when product is CLOSED
  #CLOSED is either when the posting is canceled or filled. we don't even have 'canceled' built in. eventually we'll put a control for the admin (or producer, i guess) to
  #cancel the posting. if/when you want to 'cancel' a posting we'll probably need to implement it. it will depend on if there are outstanding orders or not.
  def self.states
    {OPEN: 0, COMMITMENTZONE: 1, CLOSED: 2}
  end

  #required attributes: price, description, live, delivery_date, order_cutoff, state, user_id, product_id, unit_id
  #optional attributes: description_body, price_body, unit_body, important_notes, important_notes_body, product_id_code, units_per_case, order_minimum_producer_net, posting_recurrence_id

  validates :price, :description, :delivery_date, :order_cutoff, :state, presence: true
  validates :state, inclusion: Posting.states.values
  validates_presence_of :user, :product, :unit
  validates :price, numericality: { greater_than: 0 }

  validates :units_per_case, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :order_minimum_producer_net, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true    

  validate :important_notes_body_not_present_without_important_notes, :delivery_date_not_sunday, :order_cutoff_must_be_before_delivery_date
  validate :commission_is_set, on: :create
  before_create :delivery_date_must_be_after_today  

  def self.close(postings_closeable)

    if postings_closeable && postings_closeable.any?

      postings_closeable.each do |posting_closeable|
        #close out the posting so admin doesn't have to deal with it.
        #here at the order cutoff is the time to close out the posting so that admin doesn't have to see it on their
        #radar screen. or is this the right time? say that order cutoff is on monday and delivery friday. but say on wednesday we also have some
        #products being delivered. if we close out this posting due to insufficient quantity on monday then on wednesday the delivery notification
        #would go out to the user. this might be confusing. on the other hand, the unfilled folks might want to know earlier rather than later so
        #they can take measures to procure similar such food elsehow.
        posting_closeable.fill(0)
      end

    end

  end

  def creditor_order
    return creditor_orders.last
  end

  def self.postings_by_creditor(delivery_date)

    all_postings = Posting.where(delivery_date: delivery_date)
    postings_by_creditor = {}

    all_postings.each do |posting|

      creditor = posting.get_creditor

      if postings_by_creditor[creditor].nil?
        postings_by_creditor[creditor] = []
      end

      postings_by_creditor[creditor] << posting

    end

    return postings_by_creditor

  end

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

  def biggest_order_minimum_producer_net_outstanding
    #this posting has a producer and that producer might have a distributor. among those possible three entities, each could
    #have an order minimum. we here want to return the greatest deficiency of those three

    biggest_outstanding = 0

    temp = order_minimum_producer_net_outstanding

    if temp > biggest_outstanding
      biggest_outstanding = temp
    end

    temp = user.order_minimum_producer_net_outstanding(order_cutoff)

    if temp > biggest_outstanding
      biggest_outstanding = temp
    end

    if user.distributor
      temp = user.distributor.order_minimum_producer_net_outstanding(order_cutoff)
      if temp > biggest_outstanding
        biggest_outstanding = temp
      end
    end

    return biggest_outstanding

  end

  def order_minimum_producer_net_outstanding

    if order_minimum_producer_net.nil? || order_minimum_producer_net == 0
      return 0
    end

    return [(order_minimum_producer_net - inbound_order_value_producer_net).round(2), 0].max

  end

  def inbound_order_value_producer_net

    if state?(:CLOSED)
      num_units = num_units_filled
    else
      num_units = inbound_num_units_ordered
    end
    
    return (num_units * get_producer_net_unit).round(2)

  end

  def outbound_order_value_producer_net

    inbound = inbound_order_value_producer_net

    if order_minimum_producer_net.nil?
      return inbound
    end

    if inbound > order_minimum_producer_net
      return inbound
    else
      return 0
    end

  end

  def commission_per_unit
    commission_factor = get_commission_factor
    commission_per_unit = (price * commission_factor).round(2)
    return commission_per_unit
  end

  def get_commission_factor
    return ProducerProductUnitCommission.get_current_commission_factor(user, product, unit)
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

  def state?(state_key)
    return state == Posting.states[state_key]
  end

  def transition(input)
    
    new_state = state

    case state


    when Posting.states[:OPEN]
      case input
      when :order_cutoffed

        if Time.zone.now >= order_cutoff
          new_state = Posting.states[:COMMITMENTZONE]

          update(live: false)
          
          tote_items.where(state: ToteItem.states[:ADDED]).each do |tote_item|
            tote_item.transition(:system_removed)
          end            

          tote_items.where(state: ToteItem.states[:AUTHORIZED]).each do |tote_item|
            tote_item.transition(:order_cutoffed)
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

    return inbound_order_value_producer_net >= order_minimum_producer_net

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

  def num_units_unfilled
    return total_quantity_ordered_from_creditor - num_units_filled
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

  def expected_fill_quantity(tote_item)

    additional_units_required_to_fill_items_case = additional_units_required_to_fill_items_case(tote_item)

    if additional_units_required_to_fill_items_case == 0
      return tote_item.quantity
    end

    if tote_item.state?(:AUTHORIZED) || tote_item.state?(:COMMITTED)
      queue_quantity_before_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where("authorized_at < ?", tote_item.authorized_at).sum(:quantity)
    elsif tote_item.state?(:ADDED)
      queue_quantity_before_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).sum(:quantity) +
        tote_items.where(user: tote_item.user, state: ToteItem.states[:ADDED]).where("created_at < ?", tote_item.created_at).sum(:quantity)
    end

    case_quantity_before_item = queue_quantity_before_item % units_per_case
    quantity_needed_before_to_fill_case = units_per_case - case_quantity_before_item

    if tote_item.quantity < quantity_needed_before_to_fill_case
      return 0
    else
      return quantity_needed_before_to_fill_case + ((tote_item.quantity - quantity_needed_before_to_fill_case) / units_per_case) * units_per_case
    end

  end

  def additional_units_required_to_fill_items_case(tote_item)

    if units_per_case.nil?
      return 0
    end

    if tote_item.state?(:ADDED)
      
      queue_quantity_through_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).sum(:quantity) +
        tote_items.where(user: tote_item.user, state: ToteItem.states[:ADDED]).where("created_at <= ?", tote_item.created_at).sum(:quantity)
      existing_quantity_after_item = tote_items.where(user: tote_item.user, state: ToteItem.states[:ADDED]).where("created_at > ?", tote_item.created_at).sum(:quantity)

    elsif tote_item.state?(:AUTHORIZED) || tote_item.state?(:COMMITTED)      

      queue_quantity_through_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where("authorized_at <= ?", tote_item.authorized_at).sum(:quantity)
      existing_quantity_after_item = tote_items.where(state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where("authorized_at > ?", tote_item.authorized_at).sum(:quantity)

    end

    quantity_needed_after_to_fill_items_case = (units_per_case - (queue_quantity_through_item % units_per_case)) % units_per_case

    return [0, quantity_needed_after_to_fill_items_case - existing_quantity_after_item].max

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

  def total_quantity_ordered_from_creditor

    unit_count = total_quantity_ordered

    if units_per_case && units_per_case > 1
      unit_count = (unit_count / units_per_case) * units_per_case
    end

    return unit_count

  end

  def subscribable?    
    return posting_recurrence && posting_recurrence.on
  end

  private

    def get_first_committed_tote_item
      return tote_items.where(state: ToteItem.states[:COMMITTED]).order("tote_items.id").first    
    end

    def important_notes_body_not_present_without_important_notes

      if !important_notes_body.blank?
        if important_notes.blank?
          errors.add(:important_notes, "can't have important_notes_body without important_notes")
          return false
        end
      end

      return true

    end
    
    def delivery_date_not_sunday
      if delivery_date != nil && delivery_date.sunday?
        errors.add(:delivery_date, "delivery date can not be Sunday")
      end
    end

    def delivery_date_must_be_after_today      

      if delivery_date.nil? || delivery_date <= Time.zone.today
        errors.add(:delivery_date, "delivery date must be after today")
        return false
      end

      return true

    end

    def order_cutoff_must_be_before_delivery_date

      if delivery_date.nil?
        errors.add(:delivery_date, "delivery date must be specified")
        return
      end

      if delivery_date.nil? || order_cutoff.nil? || order_cutoff > delivery_date
        errors.add(:order_cutoff, "commitment zone must start prior to delivery date")
      end

    end

    def commission_is_set

      commission = ProducerProductUnitCommission.where(user: user, product: product, unit: unit)

      if commission.count == 0
        errors.add(:commission_is_set, "commission must be set for producer/product/unit")
        return false
      end

      return true

    end

end
