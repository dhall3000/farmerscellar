class Posting < ActiveRecord::Base
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
            tote_items.each do |tote_item|
              if tote_item.state?(:ADDED)
                tote_item.transition(:system_removed)                
              end
            end
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

  def self.product_name_from_posting_id(id)
  	posting = Posting.find(id)
  	if posting != nil
  		product = Product.find(posting.id)
  		if product != nil
  			product.name
  		end
  	end
  end

  def queue_quantity_through_item_plus_users_added_items(tote_item)

    ti = tote_items.find_by(id: tote_item.id)

    if ti.nil?
      return 0
    end

    if tote_item.authorized_at.nil?      
      filtered_tote_items = tote_items
    else      
      filtered_tote_items = tote_items.where("authorized_at <= ?", tote_item.authorized_at)
    end
    
    authorized_or_committed_quantity = total_quantity_authorized_or_committed(filtered_tote_items)
    added_tote_items_for_user_quantity = tote_items.where(user_id: tote_item.user_id, state: ToteItem.states[:ADDED]).sum(:quantity)
    
    total_quantity = authorized_or_committed_quantity + added_tote_items_for_user_quantity

    return total_quantity

  end

  def additional_units_required_to_fill_items_case(tote_item)

    if units_per_case.nil? || units_per_case < 2
      return 0
    end

    total_quantity = total_quantity_authorized_or_committed

    #this is a bit non-obvious. remember that this computed value is going to be displayed to the user
    #right after they ADD a tote item. we'll also display this data in the tote. the former won't be authorized
    #while the latter might be. especially in the former case we want to user to feel the impact of their order so we
    #need to include in the count this user's ADDED quantity
    added_tote_items_for_user = tote_items.where(user_id: tote_item.user_id, state: ToteItem.states[:ADDED])
    total_quantity += added_tote_items_for_user.sum(:quantity)

    up_through_item_quantity = queue_quantity_through_item_plus_users_added_items(tote_item)

    num_full_cases = total_quantity / units_per_case
    total_units_in_full_cases = num_full_cases * units_per_case

    if total_units_in_full_cases >= up_through_item_quantity
      return 0
    end

    additional_units_required_to_fill_items_case = (total_units_in_full_cases + units_per_case) - total_quantity

    return additional_units_required_to_fill_items_case

  end

  def total_quantity_authorized_or_committed(tis = nil)

    if tis.nil?
      tis = tote_items
    end
    
    authorized_or_committed_tote_items = tis.where("state = ? or state = ?", ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED])

    return authorized_or_committed_tote_items.sum(:quantity)

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
