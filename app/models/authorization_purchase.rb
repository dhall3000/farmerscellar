class AuthorizationPurchase < ActiveRecord::Base
  belongs_to :authorization
  belongs_to :purchase
end
