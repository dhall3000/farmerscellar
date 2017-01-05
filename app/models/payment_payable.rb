class PaymentPayable < ApplicationRecord
  has_many :user_payment_payables
  #'users' now stores reference to 'creditor'. see method 'get_creditor' in model User and this line of code in model BulkPurchase: payment_payable.users << producer.get_creditor
  has_many :users, through: :user_payment_payables

  has_many :payment_payable_tote_items
  has_many :tote_items, through: :payment_payable_tote_items

  has_many :payment_payable_payments
  has_many :payments, through: :payment_payable_payments

  def amount_outstanding
    return (amount - amount_paid).round(2)
  end

  def apply(apply_amount_intended)

    if apply_amount_intended < 0
      return
    end

    if fully_paid
      return
    end

    if amount_paid == amount
      update(fully_paid: true)
      return
    end    

    if apply_amount_intended >= amount_outstanding
      apply_amount_actual = amount_outstanding
      update(fully_paid: true, amount_paid: amount)      
    else
      apply_amount_actual = apply_amount_intended
      update(amount_paid: (amount_paid + apply_amount_intended).round(2))
    end    

    return apply_amount_actual

  end

end