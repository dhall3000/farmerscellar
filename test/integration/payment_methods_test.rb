
require 'integration_helper'
require 'utility/rake_helper'

class PaymentMethodsTest < IntegrationHelper

  test "creditororder should balance on second payment when first cod payment insufficient" do
    #payment comes before filling

    assert_equal 0, CreditorOrder.count
    admin = do_atorder_payment_setup(:CASH, :ONDELIVERY)
    assert_equal 1, CreditorOrder.count
    creditor_order = CreditorOrder.first

    #ensure payment receipts are turned on
    bi = creditor_order.business_interface
    bi.update(payment_receipt_email: bi.order_email)
    creditor_order.reload
    
    #verify this corder displays
    creditor_orders_index_verify_presence(creditor_order)

    #go to creditororder#show
    get creditor_order_path(creditor_order)
    assert_response :success
    assert_template 'creditor_orders/show'
    assert_select 'p', "OPEN"
    assert_select 'p', number_to_currency(0)
    #go to payment#new
    get new_payment_path
    assert_response :success
    assert_template 'payments/new'    
    #create a payment equal to a third the balance        
    create_payment(creditor_order.order_value_producer_net / 3, amount_applied = 0, notes = "hello there", creditor_order)
    #now do the fill
    fully_fill_creditor_order(creditor_order)
    assert creditor_order.reload.balance > 0
    assert_not creditor_order.balanced?
    #the new balance should be 2/3 the old balance
    assert_equal ((creditor_order.order_value_producer_net * 2) / 3).round(2), creditor_order.balance    
    #now create a payment equal to two thirds the balance, which is the remainder of the balance
    create_payment_full_balance(creditor_order)

    assert creditor_order.reload.balanced?
    assert_equal 0, creditor_order.balance
    assert creditor_order.state?(:CLOSED)

    travel_back

  end

  test "creditororder should balance on second payment when first cod payment insufficient 2" do
    #the only difference on this '2' test is that filling comes before payment

    #this is so that later, once a PP has been created, we can pluck it out and verify that it's only partially paid.
    #then after we square up with another payment we can again verify it, this time that it's been fully paid
    assert_equal 0, PaymentPayable.count

    assert_equal 0, CreditorOrder.count
    admin = do_atorder_payment_setup(:CASH, :ONDELIVERY)
    assert_equal 1, CreditorOrder.count
    creditor_order = CreditorOrder.first

    #ensure payment receipts are turned off
    bi = creditor_order.business_interface
    bi.update(payment_receipt_email: nil)
    creditor_order.reload

    fully_fill_creditor_order(creditor_order)
    assert creditor_order.balance > 0
    assert_not creditor_order.balanced?
    original_balance = creditor_order.balance

    log_in_as(admin)
    #go to creditororder#index
    get creditor_orders_path
    assert_response :success
    assert_template 'creditor_orders/index'    
    #verify this corder displays
    assert_select 'h2', "Open Orders"
    assert_select 'p', "Cash on delivery"
    #verify the business name shows up
    assert_select 'a[href=?].thumbnail', creditor_order_path(creditor_order)
    #verify this corder has positive balance
    assert_select 'p', number_to_currency(creditor_order.balance)
    #go to creditororder#show
    get creditor_order_path(creditor_order)
    assert_response :success
    assert_template 'creditor_orders/show'
    assert_select 'p', "OPEN"
    assert_select 'p', number_to_currency(creditor_order.balance)
    #go to payment#new
    get new_payment_path
    assert_response :success
    assert_template 'payments/new'
    #create a payment equal to a third the balance
    post payments_path, params: {creditor_order_id: creditor_order.id, payment: {amount: (creditor_order.balance / 3).round(2), amount_applied: 0, notes: "hello there!", }}
    #verify now at creditororder#show
    assert_response :redirect
    assert_redirected_to creditor_order_path(creditor_order)
    follow_redirect!

    #verify there's a partially paid payment_payable
    assert_equal 1, PaymentPayable.count
    pp = PaymentPayable.first
    assert pp.amount > 0
    assert pp.amount_paid > 0
    assert pp.amount > pp.amount_paid
    assert_not pp.fully_paid

    #verify balance displays
    assert_select 'p', number_to_currency(creditor_order.reload.balance)
    #verify balance is a third what it was but still positive
    assert creditor_order.balance > 0
    #the new balance should be 2/3 the old balance
    assert_equal ((original_balance * 2) / 3).round(2), creditor_order.balance    
    #now create a payment equal to two thirds the balance
    post payments_path, params: {creditor_order_id: creditor_order.id, payment: {amount: ((original_balance * 2) / 3).round(2), amount_applied: 0, notes: "hello there!", }}
    #verify now at creditororder#show
    assert_response :redirect
    assert_redirected_to creditor_order_path(creditor_order)
    follow_redirect!
    #verify balance displays zero
    assert_select 'p', number_to_currency(0)
    #verify state displays CLOSED
    assert_select 'p', "CLOSED"

    #verify that the previously partially paid pp is now fully paid
    assert pp.reload.amount > 0
    assert pp.amount_paid > 0
    assert_equal pp.amount, pp.amount_paid
    assert pp.fully_paid

    travel_back

  end

  test "automated payment engine should not process non paypal payment payables" do
    
    nuke_all_postings
    
    distributor = create_distributor
    
    producer1 = create_producer(name = "producer1 name", email = "producer1@p.com", distributor)
    producer1.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:PAYPAL])
    assert producer1.reload.get_business_interface.payment_method?(:PAYPAL)
    posting1 = create_posting(farmer = producer1, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil)
    
    producer2 = create_producer(name = "producer2 name", email = "producer2@p.com", distributor = nil, order_min = 0)
    producer2.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CASH])
    assert producer2.reload.get_business_interface.payment_method?(:CASH)
    posting2 = create_posting(farmer = producer2, price = 5, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil)

    bob = create_new_customer("bob", "bob@b.com")
    ti1 = create_tote_item(bob, posting1, quantity = 10)        
    ti2 = create_tote_item(bob, posting2, quantity = 10)    

    assert ti1.state?(:ADDED)
    assert ti2.state?(:ADDED)

    create_one_time_authorization_for_customer(bob)
    assert ti1.reload.state?(:AUTHORIZED)
    assert ti2.reload.state?(:AUTHORIZED)

    assert_equal posting1.delivery_date, posting2.delivery_date
    travel_to posting1.order_cutoff

    assert_equal 0, CreditorOrder.count
    RakeHelper.do_hourly_tasks
    assert_equal 2, CreditorOrder.count

    assert ti1.reload.state?(:COMMITTED)
    assert ti2.reload.state?(:COMMITTED)

    travel_to posting1.delivery_date + 12.hours

    assert_equal 0, PurchaseReceivable.count
    assert_equal 0, PaymentPayable.count
    assert_equal 0, CreditorObligation.count
    
    fully_fill_all_creditor_orders
    
    assert_equal 2, PurchaseReceivable.count
    assert_equal 2, PaymentPayable.count
    assert_equal 2, CreditorObligation.count

    assert_equal 1, CreditorObligation.first.payment_payables.count
    assert_equal 1, CreditorObligation.last.payment_payables.count

    assert_equal 0, CreditorObligation.first.payments.count
    assert_equal 0, CreditorObligation.last.payments.count

    assert ti1.reload.state?(:FILLED)
    assert ti2.reload.state?(:FILLED)

    assert_not CreditorObligation.first.balanced?
    assert_not CreditorObligation.last.balanced?

    travel_to posting1.delivery_date + 22.hours
    assert_equal 0, Payment.count
    RakeHelper.do_hourly_tasks
    assert_equal 1, Payment.count

    co_one_payment = producer1.get_creditor.creditor_orders.first.creditor_obligation
    co_no_payments = producer2.get_creditor.creditor_orders.first.creditor_obligation

    assert_equal 1, co_one_payment.payments.count
    assert co_one_payment.balanced?

    assert_equal 0, co_no_payments.payments.count
    assert_not co_no_payments.balanced?
    assert co_no_payments.balance > 0.0

    assert ti1.payment_payables.first.fully_paid
    assert_not ti2.payment_payables.first.fully_paid

    travel_back

  end

end