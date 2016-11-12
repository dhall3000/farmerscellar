class CreditorOrderPosting < ApplicationRecord
  belongs_to :creditor_order
  belongs_to :posting
end
