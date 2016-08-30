class CreatePartnerDeliveries < ActiveRecord::Migration
  def change
    create_table :partner_deliveries do |t|
      t.string :partner
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :partner_deliveries, :users
  end
end
