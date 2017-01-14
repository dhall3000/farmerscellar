class AddSelfReferenceToFoodCategories < ActiveRecord::Migration
  def change
    add_column :food_categories, :parent_id, :integer
    add_index :food_categories, :parent_id
    add_foreign_key :food_categories, :food_categories, column: :parent_id
  end
end