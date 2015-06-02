class AddFeeAmountToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :fee_amount, :float
  end
end
