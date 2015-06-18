class CreatePurchasePurchaseReceivables < ActiveRecord::Migration
  def change
    create_table :purchase_purchase_receivables do |t|
      t.references :purchase, index: true
      t.references :purchase_receivable, index: true

      t.timestamps null: false
    end
    add_foreign_key :purchase_purchase_receivables, :purchases
    add_foreign_key :purchase_purchase_receivables, :purchase_receivables
  end
end
