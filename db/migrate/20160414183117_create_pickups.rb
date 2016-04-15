class CreatePickups < ActiveRecord::Migration
  def change
    create_table :pickups do |t|
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :pickups, :users
  end
end
