class AddUserRefToUsers < ActiveRecord::Migration
  def change
    add_column :users, :distributor_id, :integer
    add_index :users, :distributor_id
    add_foreign_key :users, :users, column: :distributor_id
  end
end
