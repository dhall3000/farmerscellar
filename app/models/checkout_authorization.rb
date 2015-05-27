class CheckoutAuthorization < ActiveRecord::Base
  belongs_to :checkout
  belongs_to :authorization
end
