class Authorization < ActiveRecord::Base
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations

  has_many :authorization_purchases
  has_many :purchases, through: :authorization_purchases
end
