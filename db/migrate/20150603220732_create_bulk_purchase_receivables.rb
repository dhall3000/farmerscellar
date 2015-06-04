class CreateBulkPurchaseReceivables < ActiveRecord::Migration
  def change
    create_table :bulk_purchase_receivables, id: false do |t|
      t.references :purchase_receivable, index: true
      t.references :bulk_purchase, index: true

      t.timestamps null: false
    end
    add_foreign_key :bulk_purchase_receivables, :purchase_receivables
    add_foreign_key :bulk_purchase_receivables, :bulk_purchases
  end
end
