class CreateBulkPurchases < ActiveRecord::Migration
  def change
    create_table :bulk_purchases do |t|

      t.timestamps null: false
    end
  end
end
