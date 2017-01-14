class AddIndexToFoodCategoryName < ActiveRecord::Migration[5.0]
  def change
    add_index :food_categories, :name
  end
end