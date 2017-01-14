class FoodCategory < ApplicationRecord
  belongs_to :parent, class_name: "FoodCategory", foreign_key: "parent_id"
  has_many :children, class_name: "FoodCategory", foreign_key: "parent_id"
  has_many :products

  validate :max_one_root_object

  private

    def max_one_root_object
      if parent.nil? && FoodCategory.where(parent: nil).count > 0
        errors.add(:parent, "Can't have more than one root food category")
      end
    end

end