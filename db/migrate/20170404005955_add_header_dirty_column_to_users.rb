class AddHeaderDirtyColumnToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :header_data_dirty, :boolean, default: true
  end
end