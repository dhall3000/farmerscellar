class AddNonNullConstraintToPaymentsAmount < ActiveRecord::Migration[5.0]
  def change

    Payment.all.each do |p|
      if p.amount.nil?
        p.update(amount: 0.0)
      end
    end

    change_column :payments, :amount, :float, default: 0.0, null: false

  end
end