class AddPriceAndQuantityColumnsToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :price, :float
    add_column :subscriptions, :quantity, :integer
  end
end
