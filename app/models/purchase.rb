class Purchase < ActiveRecord::Base
  serialize :response

  has_many :bulk_purchase_purchases
  has_many :bulk_purchases, through: :bulk_purchase_purchases
end
