class CreateAccessCodes < ActiveRecord::Migration
  def change
    create_table :access_codes do |t|
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :access_codes, :users
  end
end
