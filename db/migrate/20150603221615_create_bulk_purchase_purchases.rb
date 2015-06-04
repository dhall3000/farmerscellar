class CreateBulkPurchasePurchases < ActiveRecord::Migration
  def change
    create_table :bulk_purchase_purchases, id: false do |t|
      t.references :purchase, index: true
      t.references :bulk_purchase, index: true

      t.timestamps null: false
    end
    add_foreign_key :bulk_purchase_purchases, :purchases
    add_foreign_key :bulk_purchase_purchases, :bulk_purchases
  end
end
