class RenameBulkPurchaseColumns < ActiveRecord::Migration
  def change
  	rename_column :bulk_purchases, :total_gross, :gross
  	rename_column :bulk_purchases, :total_commission, :commission
  	rename_column :bulk_purchases, :total_net, :net
  end
end
