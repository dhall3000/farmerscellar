class Product < ApplicationRecord
	has_many :postings
  belongs_to :food_category

	validates :name, presence: true
end
