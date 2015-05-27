class Checkout < ActiveRecord::Base
  serialize :response

  has_many :tote_item_checkouts
  has_many :tote_items, through: :tote_item_checkouts
  
  has_many :checkout_authorizations
  has_many :authorizations, through: :checkout_authorizations
end