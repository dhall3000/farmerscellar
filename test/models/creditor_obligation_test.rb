require 'test_helper'

class CreditorObligationTest < ActiveSupport::TestCase
  
  #case1: pp10, p15, pp10, p15, pp10: balance = 0
  test "case 1 funds exchange should check out" do

    #create creditor order
    corder = create_creditor_order
    #an obligation doesn't arise until actual value exchanges hands so there should be none yet
    assert_not corder.creditor_obligation

    #add a $10 payment_payable
    pp1 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp1.save
    corder.add_payment_payable(pp1)
    #an obligation arises once actual value exchanges hands so there should be one now
    assert corder.creditor_obligation
    assert corder.creditor_obligation.balance > 0
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    assert_not pp1.fully_paid
    assert pp1.amount_paid < pp1.amount
    assert_equal 0, pp1.payments.count

    #add a $15 payment
    p1 = Payment.new(amount: 15)
    assert p1.save
    corder.add_payment(p1)
    assert corder.creditor_obligation    
    assert corder.creditor_obligation.balance < 0
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    assert pp1.reload.fully_paid
    assert_equal pp1.amount, pp1.amount_paid
    assert_equal pp1.amount, p1.amount_applied
    assert_equal 1, pp1.payments.count
    assert_equal 1, p1.payment_payables.count

    #add a $10 payment_payable
    pp2 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp2.save
    corder.add_payment_payable(pp2)
    #an obligation arises once actual value exchanges hands so there should be one now
    assert corder.creditor_obligation
    assert corder.creditor_obligation.balance > 0
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    assert_not pp2.fully_paid
    assert pp2.amount_paid < pp2.amount
    assert pp2.amount_paid > 0
    assert_equal p1.amount, p1.amount_applied
    assert_equal 1, pp2.payments.count
    assert_equal 2, p1.payment_payables.count

    #add a $15 payment
    p2 = Payment.new(amount: 15)
    assert p2.save
    corder.add_payment(p2)
    assert corder.creditor_obligation    
    assert corder.creditor_obligation.balance < 0
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    assert pp2.reload.fully_paid
    assert_equal pp2.amount, pp2.amount_paid
    #assert_equal pp2.amount, p2.amount_applied
    assert p2.amount_applied > 0 && p2.amount_applied < p2.amount
    assert_equal 2, pp2.payments.count
    assert_equal 1, p2.payment_payables.count

    #add a $10 payment_payable
    pp3 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp3.save
    corder.add_payment_payable(pp3)
    #an obligation arises once actual value exchanges hands so there should be one now
    assert corder.creditor_obligation
    assert_equal 0.0, corder.creditor_obligation.balance
    assert corder.balanced?
    assert corder.creditor_obligation.balanced?
    assert pp3.fully_paid
    assert_equal pp3.amount, pp3.amount_paid
    assert_equal p2.amount, p2.amount_applied
    assert_equal 1, pp3.payments.count
    assert_equal 2, p2.payment_payables.count

  end

  #p15, pp10, p15, pp10, pp10: balance = 0
  test "case 2 funds exchange should check out" do

    #create creditor order
    corder = create_creditor_order
    #an obligation doesn't arise until actual value exchanges hands so there should be none yet
    assert_not corder.creditor_obligation

    #add a $15 payment
    p1 = Payment.new(amount: 15)
    assert p1.save
    corder.add_payment(p1)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert corder.creditor_obligation.balance < 0
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    #assert pp1.reload.fully_paid
    #assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal 0, p1.amount_applied
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 0, p1.payment_payables.count


    #add a $10 payment_payable
    pp1 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp1.save
    corder.add_payment_payable(pp1)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert corder.creditor_obligation.balance < 0
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp1.fully_paid
    assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal pp1.amount, p1.amount_applied
    #verify p/pp associations    
    assert_equal 1, pp1.payments.count
    assert_equal 1, p1.payment_payables.count


    #add a $15 payment
    p2 = Payment.new(amount: 15)
    assert p2.save
    corder.add_payment(p2)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -20, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    #assert pp1.reload.fully_paid
    #assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal 0, p2.amount_applied
    #verify p/pp amount_outstanding
    assert p1.amount_outstanding > 0
    assert_equal 0, pp1.amount_outstanding
    assert_equal p2.amount, p2.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 0, p2.payment_payables.count


    #add a $10 payment_payable
    pp2 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp2.save
    corder.add_payment_payable(pp2)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -10, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp2.fully_paid
    assert_equal pp2.amount, pp2.amount_paid
    #verify p: amount_applied
    assert_equal p1.amount, p1.amount_applied
    assert_equal 5, p2.amount_applied
    #verify p/pp associations
    assert_equal 2, p1.payment_payables.count
    assert_equal 1, p2.payment_payables.count
    assert_equal 1, pp1.payments.count
    assert_equal 2, pp2.payments.count

    
    #add a $10 payment_payable
    pp3 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp3.save
    corder.add_payment_payable(pp3)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert 0, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert corder.balanced?
    assert corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp3.fully_paid
    assert_equal pp3.amount, pp3.amount_paid
    #verify p: amount_applied
    assert_equal p1.amount, p1.amount_applied
    assert_equal p2.amount, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, p1.amount_outstanding
    assert_equal 0, p2.amount_outstanding
    assert_equal 0, pp1.amount_outstanding
    assert_equal 0, pp2.amount_outstanding
    assert_equal 0, pp3.amount_outstanding
    #verify p/pp associations
    assert_equal 2, p1.payment_payables.count
    assert_equal 2, p2.payment_payables.count
    assert_equal 1, pp1.payments.count
    assert_equal 2, pp2.payments.count
    assert_equal 1, pp3.payments.count

  end

  #pp10, p15, pp10, p20, pp10: balance = -5
  test "case 3 funds exchange should check out" do

    #create creditor order
    corder = create_creditor_order
    #an obligation doesn't arise until actual value exchanges hands so there should be none yet
    assert_not corder.creditor_obligation

    #add a $10 payment_payable
    pp1 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp1.save
    corder.add_payment_payable(pp1)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -10, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert_not pp1.fully_paid
    assert_equal 0, pp1.amount_paid
    #verify p: amount_applied
    #assert_equal p1.amount, p1.amount_applied
    #assert_equal p2.amount, p2.amount_applied
    #verify p/pp amount_outstanding
    #assert_equal 0, p1.amount_outstanding
    #assert_equal 0, p2.amount_outstanding
    assert_equal pp1.amount, pp1.amount_outstanding
    #assert_equal 0, pp2.amount_outstanding
    #assert_equal 0, pp1.amount_outstanding
    #verify p/pp associations
    #assert_equal 2, p1.payment_payables.count
    #assert_equal 2, p2.payment_payables.count
    assert_equal 0, pp1.payments.count
    #assert_equal 2, pp2.payments.count
    #assert_equal 1, pp1.payments.count


    #add a $15 payment
    p1 = Payment.new(amount: 15)
    assert p1.save
    corder.add_payment(p1)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp1.reload.fully_paid
    assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal pp1.amount_paid, p1.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp1.amount_outstanding
    assert_equal 5, p1.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 1, p1.payment_payables.count
    assert_equal 1, pp1.payments.count


    #add a $10 payment_payable
    pp2 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp2.save
    corder.add_payment_payable(pp2)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert 5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert_not pp2.fully_paid
    assert pp2.amount_paid > 0
    #verify p: amount_applied
    assert_equal p1.amount, p1.amount_applied    
    #verify p/pp amount_outstanding
    assert_equal 0, p1.amount_outstanding
    assert pp2.amount_outstanding > 0 && pp2.amount_outstanding < pp2.amount
    #verify p/pp associations
    assert_equal 1, pp1.payments.count
    assert_equal 2, p1.payment_payables.count
    assert_equal 1, pp2.payments.count


    #add a $15 payment
    p2 = Payment.new(amount: 20)
    assert p2.save
    corder.add_payment(p2)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -15, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp2.reload.fully_paid
    assert pp1.reload.fully_paid
    assert_equal pp2.amount, pp2.amount_paid
    #verify p: amount_applied
    assert_equal 5, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp2.amount_outstanding
    assert_equal 15, p2.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 1, p2.payment_payables.count
    assert_equal 2, pp2.payments.count


    #add a $10 payment_payable
    pp3 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp3.save
    corder.add_payment_payable(pp3)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp3.fully_paid
    assert_equal pp3.amount, pp3.amount_paid
    #verify p: amount_applied
    assert_equal 15, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 5, p2.amount_outstanding
    assert_equal 0, pp3.amount_outstanding
    #verify p/pp associations
    assert_equal 2, p2.payment_payables.count
    assert_equal 1, pp3.payments.count

  end

  #p15, pp10, p20, pp10, pp10: balance = -5
  test "case 4 funds exchange should check out" do

    #create creditor order
    corder = create_creditor_order
    #an obligation doesn't arise until actual value exchanges hands so there should be none yet
    assert_not corder.creditor_obligation

    #add a $15 payment
    p1 = Payment.new(amount: 15)
    assert p1.save
    corder.add_payment(p1)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -15, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    #assert pp1.reload.fully_paid
    #assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    #assert_equal pp1.amount_paid, p1.amount_applied
    #verify p/pp amount_outstanding
    #assert_equal 0, pp1.amount_outstanding
    assert_equal 15, p1.amount_outstanding
    #verify p/pp associations
    assert_equal 0, p1.payment_payables.count


    #add a $10 payment_payable
    pp1 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp1.save
    corder.add_payment_payable(pp1)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp1.fully_paid
    assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal pp1.amount, p1.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp1.amount_outstanding
    assert_equal 5, p1.amount_outstanding
    #verify p/pp associations
    assert_equal 1, pp1.payments.count
    assert_equal 1, p1.payment_payables.count


    #add a $10 payment_payable
    pp2 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp2.save
    corder.add_payment_payable(pp2)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert 5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert_not pp2.fully_paid
    assert pp2.amount_paid > 0
    #verify p: amount_applied
    assert_equal p1.amount, p1.amount_applied    
    #verify p/pp amount_outstanding
    assert_equal 0, p1.amount_outstanding
    assert pp2.amount_outstanding > 0 && pp2.amount_outstanding < pp2.amount
    #verify p/pp associations
    assert_equal 1, pp1.payments.count
    assert_equal 2, p1.payment_payables.count
    assert_equal 1, pp2.payments.count


    #add a $15 payment
    p2 = Payment.new(amount: 20)
    assert p2.save
    corder.add_payment(p2)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -15, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp2.reload.fully_paid
    assert pp1.reload.fully_paid
    assert_equal pp2.amount, pp2.amount_paid
    #verify p: amount_applied
    assert_equal 5, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp2.amount_outstanding
    assert_equal 15, p2.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 1, p2.payment_payables.count
    assert_equal 2, p1.payment_payables.count
    assert_equal 2, pp2.payments.count


    #add a $10 payment_payable
    pp3 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp3.save
    corder.add_payment_payable(pp3)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp3.fully_paid
    assert_equal pp3.amount, pp3.amount_paid
    #verify p: amount_applied
    assert_equal 15, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 5, p2.amount_outstanding
    assert_equal 0, pp3.amount_outstanding
    #verify p/pp associations
    assert_equal 2, p2.payment_payables.count
    assert_equal 1, pp3.payments.count
    assert_equal 2, pp2.payments.count

  end

  #do negative payments (i.e. refund from creditor to fc)
  test "creditor obligation should balance when creditor refunds us after we overpay" do

    #create creditor order
    corder = create_creditor_order
    #an obligation doesn't arise until actual value exchanges hands so there should be none yet
    assert_not corder.creditor_obligation

    #add a $15 payment
    p1 = Payment.new(amount: 15)
    assert p1.save
    corder.add_payment(p1)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -15, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    #assert pp1.reload.fully_paid
    #assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    #assert_equal pp1.amount_paid, p1.amount_applied
    #verify p/pp amount_outstanding
    #assert_equal 0, pp1.amount_outstanding
    assert_equal 15, p1.amount_outstanding
    #verify p/pp associations
    assert_equal 0, p1.payment_payables.count


    #add a $10 payment_payable
    pp1 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp1.save
    corder.add_payment_payable(pp1)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp1.fully_paid
    assert_equal pp1.amount, pp1.amount_paid
    #verify p: amount_applied
    assert_equal pp1.amount, p1.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp1.amount_outstanding
    assert_equal 5, p1.amount_outstanding
    #verify p/pp associations
    assert_equal 1, pp1.payments.count
    assert_equal 1, p1.payment_payables.count


    #add a $10 payment_payable
    pp2 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp2.save
    corder.add_payment_payable(pp2)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert 5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert_not pp2.fully_paid
    assert pp2.amount_paid > 0
    #verify p: amount_applied
    assert_equal p1.amount, p1.amount_applied    
    #verify p/pp amount_outstanding
    assert_equal 0, p1.amount_outstanding
    assert pp2.amount_outstanding > 0 && pp2.amount_outstanding < pp2.amount
    #verify p/pp associations
    assert_equal 1, pp1.payments.count
    assert_equal 2, p1.payment_payables.count
    assert_equal 1, pp2.payments.count


    #add a $15 payment
    p2 = Payment.new(amount: 20)
    assert p2.save
    corder.add_payment(p2)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal -15, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp2.reload.fully_paid
    assert pp1.reload.fully_paid
    assert_equal pp2.amount, pp2.amount_paid
    #verify p: amount_applied
    assert_equal 5, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 0, pp2.amount_outstanding
    assert_equal 15, p2.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 1, p2.payment_payables.count
    assert_equal 2, p1.payment_payables.count
    assert_equal 2, pp2.payments.count


    #add a $10 payment_payable
    pp3 = PaymentPayable.new(amount: 10, amount_paid: 0, fully_paid: false)
    assert pp3.save
    corder.add_payment_payable(pp3)
    #verify proper existence of cobligation    
    assert corder.creditor_obligation
    #verify cobl: balance
    assert -5, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert_not corder.balanced?
    assert_not corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    assert pp3.fully_paid
    assert_equal pp3.amount, pp3.amount_paid
    #verify p: amount_applied
    assert_equal 15, p2.amount_applied
    #verify p/pp amount_outstanding
    assert_equal 5, p2.amount_outstanding
    assert_equal 0, pp3.amount_outstanding
    #verify p/pp associations
    assert_equal 2, p2.payment_payables.count
    assert_equal 1, pp3.payments.count
    assert_equal 2, pp2.payments.count


    #add a $-5 payment (i.e. creditor refunds $5 to us after we overpaid)
    p3 = Payment.new(amount: -5)
    assert p3.save
    corder.add_payment(p3)
    #verify proper existence of cobligation
    assert corder.creditor_obligation    
    #verify cobl: balance
    assert_equal 0, corder.creditor_obligation.balance
    #verify cobl/cord: balanced?
    assert corder.balanced?
    assert corder.creditor_obligation.balanced?
    #verify pp: fully_paid, amount_paid
    #assert pp2.reload.fully_paid
    #assert pp1.reload.fully_paid
    #assert_equal pp2.amount, pp2.amount_paid
    #verify p: amount_applied
    assert_equal 0, p3.amount_applied
    #verify p/pp amount_outstanding
    #assert_equal 0, pp2.amount_outstanding
    assert_equal -5, p3.amount_outstanding
    #verify p/pp associations
    #assert_equal 1, pp1.payments.count
    assert_equal 0, p3.payment_payables.count

  end

#i got bored of writing these tests so i opted out of these:
#pp10, p12.5, pp10, p12.5, pp10: balance = 5
#p12.5, pp10, p12.5, pp10, pp10: balance = 5

end