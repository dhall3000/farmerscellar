class Authorization < ActiveRecord::Base
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations
end
