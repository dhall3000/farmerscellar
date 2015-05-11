class CreateAuthorizationSetups < ActiveRecord::Migration
  def change
    create_table :authorization_setups do |t|
      t.string :token
      t.float :amount
      t.string :client_ip
      t.text :response

      t.timestamps null: false
    end
  end
end
