class CreatePurchaseBulkBuys < ActiveRecord::Migration
  def change
    create_table :purchase_bulk_buys, id: false do |t|
      t.references :purchase, index: true
      t.references :bulk_buy, index: true

      t.timestamps null: false
    end
    add_foreign_key :purchase_bulk_buys, :purchases
    add_foreign_key :purchase_bulk_buys, :bulk_buys
  end
end
