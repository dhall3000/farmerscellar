class ToteItemCheckout < ActiveRecord::Base
  belongs_to :tote_item
  belongs_to :checkout
end
