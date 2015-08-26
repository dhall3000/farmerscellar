class AddDefaultValueToUserColumn < ActiveRecord::Migration
  def change
  	change_column_default :users, :account_type, 0
  end
end
