class BulkPurchaseReceivable < ApplicationRecord
  belongs_to :purchase_receivable
  belongs_to :bulk_purchase
end
