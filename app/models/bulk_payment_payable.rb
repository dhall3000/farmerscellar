class BulkPaymentPayable < ApplicationRecord
  belongs_to :payment_payable
  belongs_to :bulk_payment
end
