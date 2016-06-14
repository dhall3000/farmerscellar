class ProducerProductUnitCommission < ActiveRecord::Base
  belongs_to :product
  belongs_to :user
  belongs_to :unit

  validates :user_id, :product_id, :unit_id, :commission, presence: true
  validates :commission, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
