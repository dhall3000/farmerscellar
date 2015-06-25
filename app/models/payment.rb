class Payment < ActiveRecord::Base
  has_many :payment_payable_payments
  has_many :payment_payables, through: :payment_payable_payments
end
