class RemoveUnitCategory < ActiveRecord::Migration
  def change
    drop_table :unit_categories
  end
end
