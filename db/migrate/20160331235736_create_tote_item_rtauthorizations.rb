class CreateToteItemRtauthorizations < ActiveRecord::Migration
  def change
    create_table :tote_item_rtauthorizations, id: false do |t|
      t.references :tote_item, index: true
      t.references :rtauthorization, index: true

      t.timestamps null: false
    end
    add_foreign_key :tote_item_rtauthorizations, :tote_items
    add_foreign_key :tote_item_rtauthorizations, :rtauthorizations
  end
end
