class FixCreditorObligationPaymentPayablesReferenceBug < ActiveRecord::Migration[5.0]
  def change
    remove_column :creditor_obligation_payment_payables, :payment_payable_id
    add_column :creditor_obligation_payment_payables, :payment_payable_id, :integer
    add_index :creditor_obligation_payment_payables, :payment_payable_id, name: "index_copp_on_pp_id"
    add_foreign_key :creditor_obligation_payment_payables, :payment_payables, column: :payment_payable_id
  end
end