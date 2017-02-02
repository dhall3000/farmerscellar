class FoodCategoryUpload < ApplicationRecord
  belongs_to :food_category
  belongs_to :upload
end