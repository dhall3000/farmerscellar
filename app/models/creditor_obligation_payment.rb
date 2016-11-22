class CreditorObligationPayment < ApplicationRecord
  belongs_to :creditor_obligation
  belongs_to :payment
end