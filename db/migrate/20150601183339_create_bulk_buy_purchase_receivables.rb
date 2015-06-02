class CreateBulkBuyPurchaseReceivables < ActiveRecord::Migration
  def change
    create_table :bulk_buy_purchase_receivables, id: false do |t|
      t.references :purchase_receivable, index: true
      t.references :bulk_buy, index: true

      t.timestamps null: false
    end
    add_foreign_key :bulk_buy_purchase_receivables, :purchase_receivables
    add_foreign_key :bulk_buy_purchase_receivables, :bulk_buys
  end
end
