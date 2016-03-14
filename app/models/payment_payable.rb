class PaymentPayable < ActiveRecord::Base
  has_many :user_payment_payables
  has_many :users, through: :user_payment_payables

  has_many :payment_payable_tote_items
  has_many :tote_items, through: :payment_payable_tote_items

  has_many :payment_payable_payments
  has_many :payments, through: :payment_payable_payments
end
