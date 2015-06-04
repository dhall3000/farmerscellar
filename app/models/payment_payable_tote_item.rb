class PaymentPayableToteItem < ActiveRecord::Base
  belongs_to :tote_item
  belongs_to :payment_payable
end
