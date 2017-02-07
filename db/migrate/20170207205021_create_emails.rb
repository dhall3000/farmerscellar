class CreateEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :emails do |t|
      t.string :subject, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end