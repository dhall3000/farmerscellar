class AddTitleColumnToUploads < ActiveRecord::Migration[5.0]
  def change
    add_column :uploads, :title, :string
    add_index :uploads, :title, unique: true
  end
end