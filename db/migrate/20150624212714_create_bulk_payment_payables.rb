class CreateBulkPaymentPayables < ActiveRecord::Migration
  def change
    create_table :bulk_payment_payables do |t|
      t.references :payment_payable, index: true
      t.references :bulk_payment, index: true

      t.timestamps null: false
    end
    add_foreign_key :bulk_payment_payables, :payment_payables
    add_foreign_key :bulk_payment_payables, :bulk_payments
  end
end
