class RemoveColumnsFromBulkBuys < ActiveRecord::Migration
  def change
  	remove_column :bulk_buys, :amount_attempted
  	remove_column :bulk_buys, :amount_actual
  end
end
