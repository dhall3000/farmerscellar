class CreateBulkBuyToteItems < ActiveRecord::Migration
  def change
    create_table :bulk_buy_tote_items, id: false do |t|
      t.references :tote_item, index: true
      t.references :bulk_buy, index: true

      t.timestamps null: false
    end
    add_foreign_key :bulk_buy_tote_items, :tote_items
    add_foreign_key :bulk_buy_tote_items, :bulk_buys
  end
end
