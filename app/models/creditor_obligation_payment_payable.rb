class CreditorObligationPaymentPayable < ApplicationRecord
  belongs_to :creditor_obligation
  belongs_to :payment_payable
end