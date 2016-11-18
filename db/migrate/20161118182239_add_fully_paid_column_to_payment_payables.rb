class AddFullyPaidColumnToPaymentPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_payables, :fully_paid, :boolean
    PaymentPayable.all.each do |pp|
      if pp.amount_paid == pp.amount
        pp.fully_paid = true
      else
        pp.fully_paid = false
      end
    end
    change_column :payment_payables, :fully_paid, :boolean, default: false, null: false
    add_index :payment_payables, :fully_paid
  end
end