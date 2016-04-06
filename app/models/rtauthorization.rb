class Rtauthorization < ActiveRecord::Base
  belongs_to :rtba

  has_many :tote_item_rtauthorizations
  has_many :tote_items, through: :tote_item_rtauthorizations
  has_many :subscriptions

  validates_presence_of :rtba, :tote_items

  def active
  	return rtba.active
  end

end