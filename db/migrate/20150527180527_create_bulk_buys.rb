class CreateBulkBuys < ActiveRecord::Migration
  def change
    create_table :bulk_buys do |t|
      t.float :amount_attempted
      t.float :amount_actual

      t.timestamps null: false
    end
  end
end
