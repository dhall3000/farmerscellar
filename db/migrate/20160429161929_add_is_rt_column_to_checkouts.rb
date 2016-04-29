class AddIsRtColumnToCheckouts < ActiveRecord::Migration
  def change
    add_column :checkouts, :is_rt, :boolean, default:false
    add_index :checkouts, :is_rt
  end
end
