class PurchaseBulkBuy < ApplicationRecord
  belongs_to :purchase
  belongs_to :bulk_buy
end
