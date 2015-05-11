class CreateAuthorizationSetupToteItems < ActiveRecord::Migration
  def change
    create_table :authorization_setup_tote_items do |t|
      t.references :authorization_setup, index: true
      t.references :tote_item, index: true

      t.timestamps null: false
    end
    add_foreign_key :authorization_setup_tote_items, :authorization_setups
    add_foreign_key :authorization_setup_tote_items, :tote_items
  end
end
