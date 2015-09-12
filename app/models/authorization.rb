class Authorization < ActiveRecord::Base
  serialize :response
  
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations
 
  validates :token, :payer_id, :amount, :correlation_id, :transaction_id, :payment_date, :gross_amount, :response, :ack, presence: true    
  validates_presence_of :checkouts

end
