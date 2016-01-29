class CreateDeliveryDropsites < ActiveRecord::Migration
  def change
    create_table :delivery_dropsites, id: false  do |t|
      t.references :delivery, index: true
      t.references :dropsite, index: true

      t.timestamps null: false
    end
    add_foreign_key :delivery_dropsites, :deliveries
    add_foreign_key :delivery_dropsites, :dropsites
  end
end
