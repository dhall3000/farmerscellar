class FixColumnName < ActiveRecord::Migration
  def change
  	rename_column :users, :user_type, :account_type
  end
end
