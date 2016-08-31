class PaymentPayablePayment < ApplicationRecord
  belongs_to :payment_payable
  belongs_to :payment
end
