class FixAuthorizationsTokenColumnName < ActiveRecord::Migration
  def change
  	rename_column :authorizations, :express_token, :token
  end
end