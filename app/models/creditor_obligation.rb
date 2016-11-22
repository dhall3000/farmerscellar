class CreditorObligation < ApplicationRecord

  belongs_to :creditor_order

  has_many :creditor_obligation_payments
  has_many :payments, through: :creditor_obligation_payments

  has_many :creditor_obligation_payment_payables
  has_many :payment_payables, through: :creditor_obligation_payment_payables

  validates_presence_of :creditor_order
  validates :balance, presence: true

  #consider 'balance' to be our value piggy bank. if our piggy bank has positive value in it it's 
  #because we're presently holding more than our fair share of the deal
  #balance == 0: we're square with creditor
  #balance > 0: we owe creditor
  #balance < 0: creditor owes us
  
  def add_payment(payment)
    payments << payment
    self.balance = (self.balance - payment.amount).round(2)
    save
  end

  def add_payment_payable(payment_payable)
    payment_payables << payment_payable
    self.balance = (self.balance + payment_payable.amount - payment_payable.amount_paid).round(2)
    save
  end

end