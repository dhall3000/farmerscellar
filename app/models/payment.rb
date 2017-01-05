class Payment < ApplicationRecord

  has_many :payment_payable_payments
  has_many :payment_payables, through: :payment_payable_payments

  #'applied' means to a payment payable
  validates :amount_applied, presence: true

  def amount_outstanding
    return (amount - amount_applied).round(2)
  end

  #'apply' means to a payment payable. so if we have a negative payment (i.e. a refund from a farmer) there is no 
  #'applying' per se. it will be that the creditor_obligation will have a balance of zero once this hypothetical
  #negative payment gets added to the obligation
  def apply(amount_to_apply)

    if amount_outstanding == 0
      return amount_to_apply
    end

    amount_just_applied = [amount_outstanding, amount_to_apply].min
    update(amount_applied: (amount_applied + amount_just_applied).round(2))

    return amount_just_applied

  end

end