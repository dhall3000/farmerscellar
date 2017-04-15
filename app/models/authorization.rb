class Authorization < ApplicationRecord
  serialize :response
  
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations
  has_many :tote_items, through: :checkouts
 
  validates :token, :payer_id, :amount, :correlation_id, :transaction_id, :payment_date, :gross_amount, :response, :ack, presence: true    
  validates_presence_of :checkouts

  #hack: this is here so i can treat auths the same as rtauths
  def checkout_subscriptions
    return []
  end

  #hack: this is here so i can treat auths the same as rtauths
  def checkout_tote_items
    tote_items
  end

  def total
    return ToteItemsController.helpers.get_gross_tote(checkout_tote_items)
  end

  def user
    if tote_items.any?
      return tote_items.first.user
    end
    return nil
  end

end