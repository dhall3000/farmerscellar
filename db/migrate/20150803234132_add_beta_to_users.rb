class AddBetaToUsers < ActiveRecord::Migration
  def change
    add_column :users, :beta, :boolean
  end
end
