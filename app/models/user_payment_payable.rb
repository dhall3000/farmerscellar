class UserPaymentPayable < ApplicationRecord
  belongs_to :user
  belongs_to :payment_payable
end
