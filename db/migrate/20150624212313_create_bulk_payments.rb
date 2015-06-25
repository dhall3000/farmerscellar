class CreateBulkPayments < ActiveRecord::Migration
  def change
    create_table :bulk_payments do |t|
      t.integer :num_payees
      t.float :total_payments_amount

      t.timestamps null: false
    end
  end
end
