class CreatePaymentPayables < ActiveRecord::Migration
  def change
    create_table :payment_payables do |t|
      t.float :amount
      t.float :amount_paid

      t.timestamps null: false
    end
  end
end
