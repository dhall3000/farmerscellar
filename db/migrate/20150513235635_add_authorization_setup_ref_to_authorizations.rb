class AddAuthorizationSetupRefToAuthorizations < ActiveRecord::Migration
  def change
    add_reference :authorizations, :authorization_setup, index: true
    add_foreign_key :authorizations, :authorization_setups
  end
end
