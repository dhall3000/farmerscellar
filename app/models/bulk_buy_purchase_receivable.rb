class BulkBuyPurchaseReceivable < ActiveRecord::Base
  belongs_to :purchase_receivable
  belongs_to :bulk_buy
end
