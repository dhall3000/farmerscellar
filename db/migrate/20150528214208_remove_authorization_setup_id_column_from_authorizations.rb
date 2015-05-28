class RemoveAuthorizationSetupIdColumnFromAuthorizations < ActiveRecord::Migration
  def change
  	remove_column :authorizations, :authorization_setup_id
  end
end
