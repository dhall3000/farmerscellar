class AddNetAmountToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :net_amount, :float
  end
end
