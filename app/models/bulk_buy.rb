class BulkBuy < ActiveRecord::Base
  has_many :admin_bulk_buys
  has_many :admins, through: :admin_bulk_buys

  has_many :bulk_buy_purchase_receivables
  has_many :purchase_receivables, through: :bulk_buy_purchase_receivables

  has_many :bulk_buy_tote_items
  has_many :tote_items, through: :bulk_buy_tote_items
end
