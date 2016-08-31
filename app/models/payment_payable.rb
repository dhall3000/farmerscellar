class PaymentPayable < ApplicationRecord
  has_many :user_payment_payables
  #'users' now stores reference to 'creditor'. see method 'get_creditor' in model User and this line of code in model BulkPurchase: payment_payable.users << producer.get_creditor
  has_many :users, through: :user_payment_payables

  has_many :payment_payable_tote_items
  has_many :tote_items, through: :payment_payable_tote_items

  has_many :payment_payable_payments
  has_many :payments, through: :payment_payable_payments
end
