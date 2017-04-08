require 'integration_helper'

class CreditorOrdersTest < IntegrationHelper

  test "open co should close when producer fails to deliver anything and admin enters zero for fill quantities" do
    nuke_all_postings
    posting = create_posting
    bob = create_new_customer("bob", "bob@b.com")
    create_tote_item(bob, posting, 1)
    create_one_time_authorization_for_customer(bob)
    travel_to posting.order_cutoff
    assert_equal 0, CreditorOrder.count
    RakeHelper.do_hourly_tasks
    assert_equal 1, CreditorOrder.count
    co = CreditorOrder.first
    assert co.state?(:OPEN)
    travel_to posting.delivery_date + 12.hours
    fill_posting(posting, 0)
    assert co.reload.state?(:CLOSED)
    travel_back
  end  

  test "state should transition properly" do

    setup_basic_subscription_through_delivery
    #i believe what's going on here is a recurring posting and so the second in the series has been generated
    assert_equal 2, Posting.count
    posting = Posting.first
    #we should be at noon on the first posting's delivery date
    assert_equal posting.delivery_date + 12.hours, Time.zone.now

    #there should be no payments
    assert_equal 0, Payment.count
    #there should be a single CreditorOrder/Obligation
    assert_equal 1, CreditorOrder.count
    creditor_order = CreditorOrder.first
    assert_equal 1, CreditorObligation.count
    creditor_obligation = CreditorObligation.first

    assert creditor_order.state?(:OPEN)
    assert creditor_obligation.balance > 0

    #now let's make the payment happen and verify things get all squared up
    dt = posting.delivery_date
    travel_to Time.zone.local(dt.year, dt.month, dt.day, 22, 0)
    RakeHelper.do_hourly_tasks

    #now there should be a payment
    assert_equal 1, Payment.count
    creditor_order.reload
    creditor_obligation.reload

    assert_equal 0.0, creditor_obligation.balance
    assert creditor_order.state?(:CLOSED)

    travel_back
    
  end  

end