class AddOrderMinimumColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :order_minimum, :float, default: 0.0, null: false
  end
end