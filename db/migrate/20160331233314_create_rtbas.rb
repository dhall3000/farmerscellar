class CreateRtbas < ActiveRecord::Migration
  def change
    create_table :rtbas do |t|
      t.string :token
      t.string :ba_id
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :rtbas, :users
  end
end
