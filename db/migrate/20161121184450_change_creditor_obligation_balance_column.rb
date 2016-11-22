class ChangeCreditorObligationBalanceColumn < ActiveRecord::Migration[5.0]
  def change
    change_column :creditor_obligations, :balance, :float, default: 0.0, null: false
  end
end