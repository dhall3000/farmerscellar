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

  def authorize_items_and_subscriptions(tote_items_to_authorize)

    if !authorized?
      return
    end

    tote_items_to_authorize.each do |tote_item|

      #transition the tote_item to AUTHORIZED
      if tote_item.state?(:ADDED)
        tote_item.transition(:customer_authorized)
      end

      #associate this tote_item with the new authorization
      self.tote_items << tote_item      

      #if this item came from a subscription, associate the subscription with this authorization
      if !tote_item.subscription.nil?
        self.subscriptions << tote_item.subscription        
      end

    end

  end

end