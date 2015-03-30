class AddUserTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :user_type, :int
    add_index :users, :user_type
  end
end
