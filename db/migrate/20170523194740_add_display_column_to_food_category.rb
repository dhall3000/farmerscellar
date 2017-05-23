class AddDisplayColumnToFoodCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :food_categories, :display, :boolean, default: true
    change_column_null :food_categories, :display, false, true
  end
end