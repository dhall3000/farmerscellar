class PurchasePurchaseReceivable < ActiveRecord::Base
  belongs_to :purchase
  belongs_to :purchase_receivable
end
