class AddLocationColumnsToDropsites < ActiveRecord::Migration
  def change
    add_column :dropsites, :city, :string
    add_column :dropsites, :state, :string
    add_column :dropsites, :zip, :integer
  end
end
