class Rtauthorization < ApplicationRecord
  belongs_to :rtba

  has_many :tote_item_rtauthorizations
  has_many :tote_items, through: :tote_item_rtauthorizations

  has_many :subscription_rtauthorizations
  has_many :subscriptions, through: :subscription_rtauthorizations

  #perhaps down the road one might want to yank the tote_items requirement. this might be so if you want to make it so that a subscription
  #can be authorized without having yet generated any tote items off of it. for now, the way subscriptions work is user adds the
  #sx and in that process .generate_new_tote_item gets called so that a toteitem and sx always go in the tote at the same time. therefore
  #it's presently impossible to attemp to authorize without tote items in the tote, hence the validation.
  validates_presence_of :rtba, :tote_items

  def authorized?
  	return rtba && rtba.active
  end

  def deauthorize  	
  	tote_items.each do |ti|
  		ti.transition(:billing_agreement_inactive)
  	end
  end

  #TODO: test this
  def authorize_items_and_subscriptions(tote_items_to_authorize, subscriptions)

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

    end

    subscriptions.each do |subscription|
      self.subscriptions << subscription
    end

  end

end