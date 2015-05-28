class BulkBuy < ActiveRecord::Base
  has_many :admin_bulk_buys
  has_many :admins, through: :admin_bulk_buys

  has_many :purchase_bulk_buys
  has_many :purchases, through: :purchase_bulk_buys
end
