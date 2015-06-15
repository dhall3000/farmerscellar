class Authorization < ActiveRecord::Base
  has_many :checkout_authorizations
  has_many :checkouts, through: :checkout_authorizations

  validates :token, presence: true
  validates :payer_id, presence: true
  validates :amount, presence: true
  validates :transaction_id, presence: true
  validates :gross_amount, presence: true
end
