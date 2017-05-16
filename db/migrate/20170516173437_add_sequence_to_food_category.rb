class AddSequenceToFoodCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :food_categories, :sequence, :string
  end
end
