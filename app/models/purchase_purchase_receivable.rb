class PurchasePurchaseReceivable < ApplicationRecord
  belongs_to :purchase
  belongs_to :purchase_receivable
end
