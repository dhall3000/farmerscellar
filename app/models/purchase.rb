class Purchase < ActiveRecord::Base
  serialize :response
  
  has_many :authorization_purchases
  has_many :authorizations, through: :authorization_purchases

  has_many :purchase_bulk_buys
  has_many :bulk_buys, through: :purchase_bulk_buys

end
