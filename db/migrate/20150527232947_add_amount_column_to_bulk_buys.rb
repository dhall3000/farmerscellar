class AddAmountColumnToBulkBuys < ActiveRecord::Migration
  def change
  	add_column :bulk_buys, :amount, :float
  end
end
