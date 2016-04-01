class Rtauthorization < ActiveRecord::Base
  belongs_to :rtba

  has_many :tote_item_rtauthorizations
  has_many :tote_items, through: :tote_item_rtauthorizations

  validates_presence_of :rtba, :tote_items
end
