class CreateCreditorObligationPaymentPayables < ActiveRecord::Migration[5.0]
  def change
    create_table :creditor_obligation_payment_payables do |t|

      t.timestamps
    end
  end
end