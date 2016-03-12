class RenamePurchaseReceivableAmountPaidAttribute < ActiveRecord::Migration
  def change
  	rename_column :purchase_receivables, :amount_paid, :amount_purchased
  end
end
