class ToteItemCapture < ActiveRecord::Base
  belongs_to :capture
  belongs_to :tote_item
end
