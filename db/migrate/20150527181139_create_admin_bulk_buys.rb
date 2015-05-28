class CreateAdminBulkBuys < ActiveRecord::Migration
  def change
    create_table :admin_bulk_buys, id: false do |t|
      t.references :user, index: true
      t.references :bulk_buy, index: true

      t.timestamps null: false
    end
    add_foreign_key :admin_bulk_buys, :users
    add_foreign_key :admin_bulk_buys, :bulk_buys
  end
end
