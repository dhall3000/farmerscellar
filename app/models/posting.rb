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

end
