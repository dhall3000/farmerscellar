class RemovePriceColumnFromSubscriptions < ActiveRecord::Migration
  def change
  	remove_column :subscriptions, :price
  end
end
