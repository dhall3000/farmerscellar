class CreateToteItemCaptures < ActiveRecord::Migration
  def change
    create_table :tote_item_captures, id: false do |t|
      t.references :capture, index: true
      t.references :tote_item, index: true

      t.timestamps null: false
    end
    add_foreign_key :tote_item_captures, :captures
    add_foreign_key :tote_item_captures, :tote_items
  end
end
