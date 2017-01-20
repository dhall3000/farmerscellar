class CreatePostingUploads < ActiveRecord::Migration[5.0]
  def change
    create_table :posting_uploads do |t|
      t.references :posting, foreign_key: true
      t.references :upload, foreign_key: true

      t.timestamps
    end
  end
end
