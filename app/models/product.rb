class Product < ApplicationRecord
	has_many :postings
	has_many :producer_product_unit_commissions
	has_many :users, through: :producer_product_unit_commissions
  belongs_to :food_category

	validates :name, presence: true
end
