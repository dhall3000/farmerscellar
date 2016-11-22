class CreateCreditorObligationPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :creditor_obligation_payments do |t|
      t.references :creditor_obligation, foreign_key: true
      t.references :payment, foreign_key: true

      t.timestamps
    end
  end
end
