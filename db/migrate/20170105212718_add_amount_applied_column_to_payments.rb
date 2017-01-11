class AddAmountAppliedColumnToPayments < ActiveRecord::Migration[5.0]
  def change

    add_column :payments, :amount_applied, :float, default: 0

    Payment.all.each do |payment|
      payment.update(amount_applied: payment.amount)
    end

    change_column :payments, :amount_applied, :float, null: false

  end
end