class AddFoodCategoryColumnToProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :products, :food_category, foreign_key: true
  end
end
