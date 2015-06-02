class AddColumnToPurchaseReceivables < ActiveRecord::Migration
  def change
    add_column :purchase_receivables, :amount_paid, :float
  end
end
