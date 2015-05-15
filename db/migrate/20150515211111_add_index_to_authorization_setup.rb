class AddIndexToAuthorizationSetup < ActiveRecord::Migration
  def change
  	add_index :authorization_setups, :token
  end
end
