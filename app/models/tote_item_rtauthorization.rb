class ToteItemRtauthorization < ActiveRecord::Base
  belongs_to :tote_item
  belongs_to :rtauthorization
end
