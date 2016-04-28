class Rtauthorization < ActiveRecord::Base
  belongs_to :rtba

  has_many :tote_item_rtauthorizations
  has_many :tote_items, through: :tote_item_rtauthorizations

  has_many :subscription_rtauthorizations
  has_many :subscriptions, through: :subscription_rtauthorizations  

  validates_presence_of :rtba, :tote_items

  def authorized?
  	return rtba && rtba.active
  end

  def deauthorize  	
  	tote_items.each do |ti|
  		ti.transition(:billing_agreement_inactive)
  	end
  end

end