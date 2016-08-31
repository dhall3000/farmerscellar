class Authorization < ApplicationRecord
  serialize :response
  
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations
 
  validates :token, :payer_id, :amount, :correlation_id, :transaction_id, :payment_date, :gross_amount, :response, :ack, presence: true    
  validates_presence_of :checkouts

  def tote_items
  	
  	if !checkouts || !checkouts.any?
  		return nil
  	end

  	checkout = checkouts.order("checkouts.id").last

  	if !checkout.tote_items || !checkout.tote_items.any?
  		return nil
  	end

  	return checkout.tote_items

  end

end