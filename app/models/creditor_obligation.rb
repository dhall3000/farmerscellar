class CreditorObligation < ApplicationRecord

  belongs_to :creditor_order

  has_many :creditor_obligation_payments
  has_many :payments, through: :creditor_obligation_payments

  has_many :creditor_obligation_payment_payables
  has_many :payment_payables, through: :creditor_obligation_payment_payables

  validates_presence_of :creditor_order
  validates :balance, presence: true

  def creditor
    return creditor_order.creditor
  end

  #consider 'balance' to be our value piggy bank. if our piggy bank has positive value in it it's 
  #because we're presently holding more than our fair share of the deal
  #balance == 0: we're square with creditor
  #balance > 0: we owe creditor
  #balance < 0: creditor owes us

  def balanced?
    return balance == 0.0
  end
  
  def add_payment(payment)
    payments << payment
    value_exchanged_hands
  end

  def add_payment_payable(payment_payable)
    payment_payables << payment_payable
    value_exchanged_hands
  end

  def self.get_unbalanced
    return CreditorObligation.joins(creditor_order: {creditor: :business_interface}).where("balance > 0.0").where("business_interfaces.payment_method = ?", BusinessInterface.payment_methods[:PAYPAL])
  end

  private
    def value_exchanged_hands
      #lead with a .save to ensure data consistency before recomputing 'balance'
      save
      payment_payables_sum = payment_payables.sum(:amount).round(2)
      payments_sum = payments.sum(:amount).round(2)
      update(balance: (payment_payables_sum - payments_sum).round(2))
      #now tell the order there's a new balance
      creditor_order.transition(:value_exchanged_hands)
    end

end