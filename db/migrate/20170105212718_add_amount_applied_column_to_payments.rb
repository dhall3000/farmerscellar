class AddAmountAppliedColumnToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :amount_applied, :float, default: 0, null: false
  end
end