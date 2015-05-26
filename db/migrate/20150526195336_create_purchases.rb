class CreatePurchases < ActiveRecord::Migration
  def change
    create_table :purchases do |t|
      t.float :amount

      t.timestamps null: false
    end
  end
end
