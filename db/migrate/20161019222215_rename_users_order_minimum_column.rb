class RenameUsersOrderMinimumColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :order_minimum, :order_minimum_producer_net
  end
end
