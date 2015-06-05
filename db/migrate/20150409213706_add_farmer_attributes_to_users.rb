class AddFarmerAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :description, :text
    add_column :users, :address, :string
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :zip, :string
    add_column :users, :phone, :string
    add_column :users, :website, :string
    add_column :users, :agreement, :boolean
  end
end
