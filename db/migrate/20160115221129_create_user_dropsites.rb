class CreateUserDropsites < ActiveRecord::Migration
  def change
    create_table :user_dropsites, id: false do |t|
      t.references :user, index: true
      t.references :dropsite, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_dropsites, :users
    add_foreign_key :user_dropsites, :dropsites
  end
end
