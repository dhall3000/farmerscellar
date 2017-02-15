class AddSizesToUploads < ActiveRecord::Migration[5.0]
  def change
    add_column :uploads, :square_size, :integer, default: 0
    add_column :uploads, :large_size, :integer, default: 0

    Upload.all.each do |upload|
      upload.update(square_size: upload.file_name.square.size, large_size: upload.file_name.large.size)
    end
  end
end