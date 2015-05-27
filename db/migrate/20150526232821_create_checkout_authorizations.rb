class CreateCheckoutAuthorizations < ActiveRecord::Migration
  def change
    create_table :checkout_authorizations, id: false do |t|
      t.references :checkout, index: true
      t.references :authorization, index: true

      t.timestamps null: false
    end
    add_foreign_key :checkout_authorizations, :checkouts
    add_foreign_key :checkout_authorizations, :authorizations
  end
end
