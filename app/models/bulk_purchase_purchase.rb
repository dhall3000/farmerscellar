class BulkPurchasePurchase < ActiveRecord::Base
  belongs_to :purchase
  belongs_to :bulk_purchase
end
