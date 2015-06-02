class UserPurchaseReceivable < ActiveRecord::Base
  belongs_to :user
  belongs_to :purchase_receivable
end
