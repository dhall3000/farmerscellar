class PurchaseReceivable < ActiveRecord::Base
  has_many :bulk_buy_purchase_receivables
  has_many :bulk_buys, through: :bulk_buy_purchase_receivables

  has_many :purchase_purchase_receivables
  has_many :purchases, through: :purchase_purchase_receivables

  has_many :user_purchase_receivables
  has_many :users, through: :user_purchase_receivables

  has_many :purchase_receivable_tote_items
  has_many :tote_items, through: :purchase_receivable_tote_items
end
