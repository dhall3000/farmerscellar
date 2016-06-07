class Posting < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  belongs_to :unit_category
  belongs_to :unit_kind
  belongs_to :posting_recurrence

  has_many :tote_items
  has_many :users, through: :tote_items

  has_many :delivery_postings
  has_many :deliveries, through: :delivery_postings

  validates :description, :quantity_available, :price, :delivery_date, :commitment_zone_start, presence: true
  validates :quantity_available, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  #the weird syntax below is due to some serious gotchas having to do with how booleans are stores or something? I have no idea. See here:
  #http://stackoverflow.com/questions/10506575/rails-database-defaults-and-model-validation-for-boolean-fields
  validates :live, inclusion: { in: [true, false] }
  validate :delivery_date_not_sunday, :delivery_date_must_be_after_today, :commitment_zone_start_must_be_before_delivery_date
  validates_presence_of :user, :product, :unit_kind, :unit_category

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
      when :past_delivery_date

        #this time is somewhat arbitrary. probably would be better to mark this as closed once delivery happened. but what if no product was
        #delivered (either cause producer didn't come through or nobody ordered). also, if you specify a time of after delivery date to
        #arbitrarily transition to CLOSED you'll bump in to the delivery_date_must_be_after_today custom validation
        if Time.zone.now >= delivery_date + 12.hours
          new_state = Posting.states[:CLOSED]
        end

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

    #first fill all the toteitems we can with the quantity provided
    #fill in FIFO order    

    #we only fill a tote item completely or not at all. so as we're running through the queue if we come across
    #a tote item we can't fill we shouldn't stop there. we should continue all the way through to the end of the
    #queue as long as we have 'quantity_remaining' looking for a tote item of smaller quantity that we can
    #completely fill
    first_committed_tote_item = get_first_committed_tote_item
    while first_committed_tote_item

      if quantity_remaining >= first_committed_tote_item.quantity
        quantity_remaining = quantity_remaining - first_committed_tote_item.quantity
        quantity_filled = quantity_filled + first_committed_tote_item.quantity        
        first_committed_tote_item.transition(:tote_item_filled)
        tote_items_filled << first_committed_tote_item
      else
        quantity_not_filled = quantity_not_filled + first_committed_tote_item.quantity
        first_committed_tote_item.transition(:tote_item_not_filled)                
        tote_items_not_filled << first_committed_tote_item
      end
      
      first_committed_tote_item = get_first_committed_tote_item

    end

    return {
      quantity_filled: quantity_filled,
      quantity_not_filled: quantity_not_filled,
      quantity_remaining: quantity_remaining,
      tote_items_filled: tote_items_filled,
      tote_items_not_filled: tote_items_not_filled
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

  def total_quantity_authorized_or_committed
    
    authorized_or_committed_tote_items = tote_items.where("state = ? or state = ?", ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED])

    unit_count = 0

    authorized_or_committed_tote_items.each do |tote_item|
      unit_count = unit_count + tote_item.quantity
    end

    return unit_count

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

    unit_count = 0

    ordered_tote_items.each do |tote_item|
      unit_count = unit_count + tote_item.quantity
    end

    return unit_count

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
      end
    end

    def commitment_zone_start_must_be_before_delivery_date

      if delivery_date.nil?
        errors.add(:delivery_date, "Delivery date must not be specified")
        return
      end

      if delivery_date.nil? || commitment_zone_start.nil? || commitment_zone_start > delivery_date
        errors.add(:commitment_zone_start, "Commitment zone must start prior to delivery date")
      end

    end

end
