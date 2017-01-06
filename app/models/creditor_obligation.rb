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

    amount_remaining_to_apply = payment.amount

    payment_payables.where(fully_paid: false).each do |pp|
      if amount_remaining_to_apply > 0.0        
        
        amount_to_apply = [pp.amount_outstanding, amount_remaining_to_apply].min
        amount_actually_applied = pp.apply(amount_to_apply)
        payment.apply(amount_actually_applied)
        amount_remaining_to_apply = (amount_remaining_to_apply - amount_actually_applied).round(2)

        if amount_actually_applied > 0.0
          payment.payment_payables << pp
        end

      end
    end

    payment.save

    value_exchanged_hands
  end

  def add_payment_payable(payment_payable)
    payment_payables << payment_payable

    payments.each do |payment|
      
      if payment.amount_outstanding == 0.0
        next
      end

      if payment_payable.amount_outstanding == 0.0
        next
      end

      amount_to_apply = [payment.amount_outstanding, payment_payable.amount_outstanding].min

      if amount_to_apply > 0.0
        payment_payable.apply(amount_to_apply)
        payment.apply(amount_to_apply)
        payment.payment_payables << payment_payable
        payment.save
        payment_payable.reload
      end

    end

    value_exchanged_hands
  end

  def self.get_positive_balanced
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