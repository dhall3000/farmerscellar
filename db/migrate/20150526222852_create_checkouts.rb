class CreateCheckouts < ActiveRecord::Migration
  def change
    create_table :checkouts do |t|
      t.string :token
      t.float :amount
      t.string :client_ip
      t.text :response

      t.timestamps null: false
    end
    add_index :checkouts, :token
  end
end
