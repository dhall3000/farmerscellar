class ToteItemCheckout < ApplicationRecord
  belongs_to :tote_item
  belongs_to :checkout
end
