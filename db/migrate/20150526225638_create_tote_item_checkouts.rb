class CreateToteItemCheckouts < ActiveRecord::Migration
  def change
    create_table :tote_item_checkouts, id: false do |t|
      t.references :tote_item, index: true
      t.references :checkout, index: true

      t.timestamps null: false
    end
    add_foreign_key :tote_item_checkouts, :tote_items
    add_foreign_key :tote_item_checkouts, :checkouts
  end
end
