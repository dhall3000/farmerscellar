class CreatePickupCodes < ActiveRecord::Migration
  def change
    create_table :pickup_codes do |t|
      t.string :code
      t.references :user, index: true

      t.timestamps null: false
    end
    add_index :pickup_codes, :code
    add_foreign_key :pickup_codes, :users
  end
end
