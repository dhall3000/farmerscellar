class RenameUploadNameColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :uploads, :name, :file_name
  end
end