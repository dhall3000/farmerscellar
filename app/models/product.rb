class Product < ActiveRecord::Base
	has_many :postings
	has_many :producer_product_commissions
	has_many :users, through: :producer_product_commissions
end