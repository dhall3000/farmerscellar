class BulkBuyPurchaseReceivable < ApplicationRecord
  belongs_to :purchase_receivable
  belongs_to :bulk_buy
end
