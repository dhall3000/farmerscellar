class PurchaseBulkBuy < ActiveRecord::Base
  belongs_to :purchase
  belongs_to :bulk_buy
end
