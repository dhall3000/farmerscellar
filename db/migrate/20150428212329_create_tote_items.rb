class CreateToteItems < ActiveRecord::Migration
  def change
    create_table :tote_items do |t|
      t.integer :quantity
      t.float :price
      t.integer :status
      t.references :posting, index: true

      t.timestamps null: false
    end
    add_foreign_key :tote_items, :postings
  end
end
