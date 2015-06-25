class PaymentPayablePayment < ActiveRecord::Base
  belongs_to :payment_payable
  belongs_to :payment
end
