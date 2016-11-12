class CreateCreditorOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :creditor_orders do |t|
      t.datetime :delivery_date

      t.timestamps
    end
    add_index :creditor_orders, :delivery_date
  end
end
