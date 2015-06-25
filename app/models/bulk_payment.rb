class BulkPayment < ActiveRecord::Base
  has_many :bulk_payment_payables
  has_many :payment_payables, through: :bulk_payment_payables
end
