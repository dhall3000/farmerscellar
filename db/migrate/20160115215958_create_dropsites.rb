class CreateDropsites < ActiveRecord::Migration
  def change
    create_table :dropsites do |t|
      t.string :name
      t.string :phone
      t.string :hours
      t.string :address
      t.text :access_instructions

      t.timestamps null: false
    end
  end
end
