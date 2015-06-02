class CreatePurchaseReceivableToteItems < ActiveRecord::Migration
  def change
    create_table :purchase_receivable_tote_items, id: false do |t|
      t.references :tote_item, index: true
      t.references :purchase_receivable, index: true

      t.timestamps null: false
    end
    add_foreign_key :purchase_receivable_tote_items, :tote_items
    add_foreign_key :purchase_receivable_tote_items, :purchase_receivables
  end
end
