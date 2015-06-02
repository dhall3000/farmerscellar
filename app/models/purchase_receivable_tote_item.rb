class PurchaseReceivableToteItem < ActiveRecord::Base
  belongs_to :tote_item
  belongs_to :purchase_receivable
end
