class UserPurchaseReceivable < ApplicationRecord
  belongs_to :user
  belongs_to :purchase_receivable
end
