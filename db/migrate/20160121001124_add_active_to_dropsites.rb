class AddActiveToDropsites < ActiveRecord::Migration
  def change
    add_column :dropsites, :active, :boolean
  end
end
