class BulkBuyToteItem < ActiveRecord::Base
  belongs_to :tote_item
  belongs_to :bulk_buy
end
