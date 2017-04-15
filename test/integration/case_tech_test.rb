require 'integration_helper'

class CaseTechTest < IntegrationHelper

  test "order email and payment receipt should show proper funds amounts if producer order quantity is less than customer order quantity due to case constraint" do

    nuke_all_postings
    units_per_case = 10
    posting = create_posting(farmer = nil, price = 1.04, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1.00)
    posting2 = create_posting(posting.user, price = 1.04, product = Product.create(name: "FakeProduct"), unit = nil, delivery_date = nil, order_cutoff = nil, nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1.00)    
    bob = create_new_customer
    ti = create_tote_item(bob, posting, 15, frequency = nil, roll_until_filled = true)
    ti2 = create_tote_item(bob, posting2, 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(bob)

    ActionMailer::Base.deliveries.clear
    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks

    #go to order cutoff and verify proper order email
    #case size is 10, inbound order quantity was 15. so the producer order should only be for quantity 10
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.first
    assert_equal "Order for #{posting.delivery_date.strftime("%A, %B")} #{posting.delivery_date.day.ordinalize} delivery", mail.subject
    assert_match "Below are orders for your upcoming delivery. If all orders are filled total sales will be $11.00", mail.body.encoded

    #now go to delivery day, process fills
    travel_to posting.delivery_date + 12.hours
    fully_fill_creditor_order(posting.creditor_order)    
    assert_equal units_per_case, ti.reload.quantity_filled
    assert_equal 1, ti2.reload.quantity_filled

    #now go to payment time and verify the payment receipt is accurate
    travel_to posting.delivery_date + 22.hours
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #there should be payment receipt, purchase receipt, bulk purchase report, bulk payment report
    assert_equal 2, ActionMailer::Base.deliveries.count
    emails = get_emails_by_subject(ActionMailer::Base.deliveries, "Payment receipt")
    assert_equal 1, emails.count
    payment_receipt = emails.first
    assert_match "Here's a 'paper' trail for the $11.00 payment we just made for the following products / quantities:", payment_receipt.body.encoded

    #this assertion is the real kicker. there should be a 'sub total' column that has this value to represent the first posting's items. customers ordered a total of $15
    #of product. however, a case constraint was in effect so only 10 units shipped so this sub total should reflect that.
    assert_match "$10.00", payment_receipt.body.encoded

    travel_back

  end

  test "should show pout page if subscription first tote item will not fill" do
    nuke_all_postings

    delivery_date = get_delivery_date(days_from_now = 10)
    if (delivery_date - 1.day).wday == STARTOFWEEK
      delivery_date += 1.day
    end
    order_cutoff = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.create_business_interface(name: "Distributor Inc.", order_email: distributor.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: distributor.email)

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor    
    producer1.save
    
    price = 1.00
    posting1 = create_posting(producer1, price, products(:apples), units(:pound), delivery_date, order_cutoff, units_per_case = 10, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, get_producer_net_unit(0.05, price))

    bob = create_user("bob", "bob@b.com")
    
    ti1_bob = create_tote_item(bob, posting1, 2, subscription_frequency = 1)

    create_rt_authorization_for_customer(bob)
  end

  test "should show pout page if subscription first tote item will only partially fill" do

  end

  test "should pay producer proper amount if partial fills exist" do
    #we're going to create a posting whose case size is 10 and then have a single customer
    #add/auth a single tote item of quantity 13. this should trigger an order to the producer of a 
    #single case and that should partially fill the customer's order. the producer should then get paid
    #the right amount

    nuke_all_postings

    days_from_now = 100
    commission = 0.05
    units_per_case = 10
    number_of_cases = 2
    number_of_units = number_of_cases * units_per_case + 3
    number_of_units_expected_in_order_email = (number_of_units / units_per_case) * units_per_case
    price = 10    

    #create a partial fill

    #create posting
    delivery_date = get_delivery_date(days_from_now)
    order_cutoff = delivery_date - 2.days
    farmer = create_producer(name = "farmer bob", email = "producer@p.com", distributor = nil, order_min = 0)
 
    product = products(:apples)
    unit = units(:pound)

    posting = create_posting(farmer, price, product, unit, delivery_date, order_cutoff, units_per_case, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, get_producer_net_unit(commission, price))
    #create customer
    customer = create_new_customer("bob", "bob@fc.com")
    customer.set_dropsite(Dropsite.first)
    #create tote items for user/posting
    tote_item = create_tote_item(customer, posting, number_of_units)
    #authorize tote items
    create_one_time_authorization_for_customer(customer)
    #fast forward to commitment zone
    assert posting.state?(:OPEN)
    travel_to posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    assert posting.reload.state?(:COMMITMENTZONE)
    #check the right order was submitted and that admin was notified
    assert_equal 1, ActionMailer::Base.deliveries.count
    #check the order was correct
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.first, farmer.get_creditor, posting, number_of_units_expected_in_order_email, units_per_case, number_of_cases)
    #do fill
    travel_to posting.delivery_date + 12.hours    
    fill_posting(posting, number_of_units_expected_in_order_email)
    assert tote_item.reload.partially_filled?
    assert_equal number_of_units_expected_in_order_email, tote_item.quantity_filled
    assert_equal number_of_units, tote_item.quantity
    #send out delivery notifications
    ActionMailer::Base.deliveries.clear
    do_delivery
    #verify delivery notification is correct
    assert_equal 1, ActionMailer::Base.deliveries.count
    delivery_notification_mail = ActionMailer::Base.deliveries.first
    verify_proper_delivery_notification_email(delivery_notification_mail, tote_item)
    ActionMailer::Base.deliveries.clear

    #jump to funds processing time
    travel_to posting.delivery_date + 22.hours    
    #do payments
    RakeHelper.do_hourly_tasks

    #smoke tests: a single purchase receivable and a single payment payable should have just been created. the former amoutn should be > than the latter
    pr = PurchaseReceivable.last
    pp = PaymentPayable.last
    assert_equal pr.amount, pr.amount_purchased
    assert_equal pp.amount, pp.amount_paid
    #verify the amount purchased is correct
    amount_purchased_expected = number_of_units_expected_in_order_email * price
    assert_equal amount_purchased_expected, pr.amount
    #compute the amount paid expected
    amount_paid_expected = (amount_purchased_expected * (1.0 - 0.035 - commission)).round(2)
    #verify the producer is paid the proper amount
    assert pr.amount > pp.amount
    assert_equal amount_paid_expected, pp.amount
    #verify the payment receipt value is proper
    verify_payment_receipt_email([posting])

    #verify the purchase receipt value is proper
    #verify_purchase_receipt_email(posting.tote_items)

    travel_back

  end

end