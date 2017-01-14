class FoodCategory < ApplicationRecord
  belongs_to :parent, class_name: "FoodCategory", foreign_key: "parent_id"
  has_many :children, class_name: "FoodCategory", foreign_key: "parent_id"
end