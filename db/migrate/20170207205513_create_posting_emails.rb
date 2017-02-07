class CreatePostingEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :posting_emails do |t|
      t.references :posting, foreign_key: true
      t.references :email, foreign_key: true

      t.timestamps
    end
  end
end
