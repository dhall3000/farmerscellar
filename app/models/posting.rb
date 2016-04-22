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
    tote_item = ToteItem.dequeue2(self.id)
    while tote_item

      if quantity_remaining >= tote_item.quantity
        quantity_remaining = quantity_remaining - tote_item.quantity
        quantity_filled = quantity_filled + tote_item.quantity        
        tote_item.transition(:tote_item_filled)
        tote_items_filled << tote_item
      else
        quantity_not_filled = quantity_not_filled + tote_item.quantity
        tote_item.transition(:not_enough_product)                
        tote_items_not_filled << tote_item
      end
      
      tote_item = ToteItem.dequeue2(self.id)

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
    #{AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, PURCHASEPENDING: 7, PURCHASED: 8, PURCHASEFAILED: 9}    
    ordered_tote_items = tote_items.where("state = ? or state = ? or state = ? or state = ? or state = ? or state = ? or state = ?",
      ToteItem.states[:AUTHORIZED],
      ToteItem.states[:COMMITTED],
      ToteItem.states[:FILLPENDING],
      ToteItem.states[:FILLED],
      ToteItem.states[:PURCHASEPENDING],
      ToteItem.states[:PURCHASED],
      ToteItem.states[:PURCHASEFAILED])

    unit_count = 0

    ordered_tote_items.each do |tote_item|
      unit_count = unit_count + tote_item.quantity
    end

    return unit_count

  end

  private
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
