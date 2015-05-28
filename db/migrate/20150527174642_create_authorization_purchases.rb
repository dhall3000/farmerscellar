class CreateAuthorizationPurchases < ActiveRecord::Migration
  def change
    create_table :authorization_purchases, id: false do |t|
      t.references :authorization, index: true
      t.references :purchase, index: true

      t.timestamps null: false
    end
    add_foreign_key :authorization_purchases, :authorizations
    add_foreign_key :authorization_purchases, :purchases
  end
end
