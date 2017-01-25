class FoodCategory < ApplicationRecord
  belongs_to :parent, class_name: "FoodCategory", foreign_key: "parent_id"
  has_many :children, class_name: "FoodCategory", foreign_key: "parent_id"
  has_many :products

  validate :max_one_root_object, on: :create

  #this is a recursive method that returns a single relation containing all the products associated with
  #all children categories + products associated with self
  def products_under
    
    pu = products
    children.each do |child|
      pu = pu.or(child.products_under)      
    end

    return pu

  end

  private

    def max_one_root_object
      if parent.nil? && FoodCategory.where(parent: nil).count > 0
        errors.add(:parent, "Can't have more than one root food category")
      end
    end

end