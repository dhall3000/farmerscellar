require 'test_helper'
require 'integration_helper'

class CreditorOrdersTest < IntegrationHelper

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
    travel_to posting.delivery_date + 22.hours
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