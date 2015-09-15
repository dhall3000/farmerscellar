class Posting < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  belongs_to :unit_category
  belongs_to :unit_kind
  has_many :tote_items

  validates :description, :quantity_available, :price, :delivery_date, presence: true
  validates :quantity_available, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  #the weird syntax below is due to some serious gotchas having to do with how booleans are stores or something? I have no idea. See here:
  #http://stackoverflow.com/questions/10506575/rails-database-defaults-and-model-validation-for-boolean-fields
  validates :live, inclusion: { in: [true, false] }

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

end
