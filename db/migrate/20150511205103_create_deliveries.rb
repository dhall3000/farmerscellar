class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.references :posting, index: true

      t.timestamps null: false
    end
    add_foreign_key :deliveries, :postings
  end
end
