class Authorization < ApplicationRecord
  serialize :response
  
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations
  has_many :tote_items, through: :checkouts
 
  validates :token, :payer_id, :amount, :correlation_id, :transaction_id, :payment_date, :gross_amount, :response, :ack, presence: true    
  validates_presence_of :checkouts

  def user
    if tote_items.any?
      return tote_items.first.user
    end
    return nil
  end

end