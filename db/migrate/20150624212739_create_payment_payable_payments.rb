class CreatePaymentPayablePayments < ActiveRecord::Migration
  def change
    create_table :payment_payable_payments do |t|
      t.references :payment_payable, index: true
      t.references :payment, index: true

      t.timestamps null: false
    end
    add_foreign_key :payment_payable_payments, :payment_payables
    add_foreign_key :payment_payable_payments, :payments
  end
end
