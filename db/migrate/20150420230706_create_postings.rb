class CreatePostings < ActiveRecord::Migration
  def change
    create_table :postings do |t|
      t.text :description
      t.integer :quantity_available
      t.float :price
      t.references :user, index: true
      t.references :product, index: true
      t.references :unit_category, index: true
      t.references :unit_kind, index: true

      t.timestamps null: false
    end
    add_foreign_key :postings, :users
    add_foreign_key :postings, :products
    add_foreign_key :postings, :unit_categories
    add_foreign_key :postings, :unit_kinds
  end
end
