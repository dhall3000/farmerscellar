class CreateEmailRecipients < ActiveRecord::Migration[5.0]
  def change
    create_table :email_recipients do |t|
      t.references :email, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
