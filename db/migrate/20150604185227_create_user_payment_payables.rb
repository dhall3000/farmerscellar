class CreateUserPaymentPayables < ActiveRecord::Migration
  def change
    create_table :user_payment_payables, id: false do |t|
      t.references :user, index: true
      t.references :payment_payable, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_payment_payables, :users
    add_foreign_key :user_payment_payables, :payment_payables
  end
end
