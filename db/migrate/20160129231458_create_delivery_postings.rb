class CreateDeliveryPostings < ActiveRecord::Migration
  def change
    create_table :delivery_postings, id: false do |t|
      t.references :posting, index: true
      t.references :delivery, index: true

      t.timestamps null: false
    end
    add_foreign_key :delivery_postings, :postings
    add_foreign_key :delivery_postings, :deliveries
  end
end
