class ChangeTokenColumnInPurchases < ActiveRecord::Migration
  def change
  	rename_column :purchases, :token, :transaction_id
  end
end
