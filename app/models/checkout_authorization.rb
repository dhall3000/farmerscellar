class CheckoutAuthorization < ApplicationRecord
  belongs_to :checkout
  belongs_to :authorization
end
