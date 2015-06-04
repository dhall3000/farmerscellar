class UserPaymentPayable < ActiveRecord::Base
  belongs_to :user
  belongs_to :payment_payable
end
