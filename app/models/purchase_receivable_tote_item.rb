class PurchaseReceivableToteItem < ApplicationRecord
  belongs_to :tote_item
  belongs_to :purchase_receivable
end
