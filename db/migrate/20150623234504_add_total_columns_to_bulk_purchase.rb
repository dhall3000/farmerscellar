class AddTotalColumnsToBulkPurchase < ActiveRecord::Migration
  def change
    add_column :bulk_purchases, :total_gross, :float
    add_column :bulk_purchases, :total_fee, :float
    add_column :bulk_purchases, :total_commission, :float
    add_column :bulk_purchases, :total_net, :float
  end
end
