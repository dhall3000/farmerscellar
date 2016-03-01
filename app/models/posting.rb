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

    total_quantity = 0

    if tote_items.nil? || !tote_items.any?
      return total_quantity
    end

    tote_items.each do |tote_item|      
      case tote_item.status
        when ToteItem.states[:AUTHORIZED]
          total_quantity = total_quantity + tote_item.quantity
        when ToteItem.states[:COMMITTED]
          total_quantity = total_quantity + tote_item.quantity
        when ToteItem.states[:FILLPENDING]
          total_quantity = total_quantity + tote_item.quantity
        when ToteItem.states[:FILLED]
          total_quantity = total_quantity + tote_item.quantity
        when ToteItem.states[:PURCHASEPENDING]
          total_quantity = total_quantity + tote_item.quantity
        when ToteItem.states[:PURCHASED]
          total_quantity = total_quantity + tote_item.quantity      
      end
    end

    return total_quantity

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
