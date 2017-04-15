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

  def checkout_subscriptions

    scrips = []

    #really what we're saying here is get a list of subscriptions for whom this auth is the first auth that sx has ever seen
    subscriptions.where(kind: Subscription.kinds[:NORMAL]).each do |subscription|
      if subscription.original_rtauthorization == self
        scrips << subscription
      end
    end

    return scrips

  end

  def checkout_tote_items

    subscription_items = []
    subscriptions.each do |subscription|
      if subscription.original_rtauthorization == self
        subscription_items << subscription.tote_items.first
      end
    end

    #and last get the items not associated with any subscription objects that also are not associated with any one time authorizations and for whom this auth was their first
    one_time_items = []
    tote_items.where(subscription: nil).where.not(id: tote_items.joins(:authorizations)).each do |tote_item|
      if tote_item.rtauthorizations.order("rtauthorizations.id").first == self
        one_time_items << tote_item
      end
    end

    tote_items = subscription_items + one_time_items

    return tote_items

  end

  def total
    sx = checkout_subscriptions
    items = checkout_tote_items
    return ToteItemsController.helpers.get_gross_tote(items)
  end

  def user
    if tote_items.any?
      return tote_items.first.user
    end
    return nil
  end

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