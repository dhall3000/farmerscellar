require 'integration_helper'

class UnconditionalPaymentTest < IntegrationHelper

	test "unconditional payment producer should get paid for unsuccessful purchases" do

		assert_equal 0, PaymentPayable.count

		bob = setup_basic_process_through_delivery

    #here, before we process payments, there already should be a payment payable
    #check to make sure it is as expected
    assert_equal 1, PaymentPayable.count
    pp = PaymentPayable.first
    assert_equal 0, pp.amount_paid
    expected_producer_net = 2 * ((1 - (0.035 * 1) - (0.05 * 1)).round(2))
    assert_equal expected_producer_net, pp.amount

    #while we're at it let's make sure the purchase receivable is up to snuff
    assert_equal 1, PurchaseReceivable.count
    pr = PurchaseReceivable.first
    assert_equal 2, pr.amount
    assert_equal 0, pr.amount_purchased
    assert_equal PurchaseReceivable.kind[:NORMAL], pr.kind
    assert_equal PurchaseReceivable.states[:READY], pr.state

    #travel to 10pm so we can process purchases and payments
    now = Time.zone.now
    ten = Time.zone.local(now.year, now.month, now.day, 22, 00)    
    travel_to ten

    #this should make the purchase fail
    FakeCaptureResponse.succeed = false
		RakeHelper.do_hourly_tasks
		FakeCaptureResponse.succeed = true

		#verify purchase failed
		assert_equal 0, pr.reload.amount_purchased
    assert_equal PurchaseReceivable.kind[:PURCHASEFAILED], pr.kind
    assert_equal PurchaseReceivable.states[:READY], pr.state

    #verify payment went through properly
    assert_equal pp.reload.amount, pp.reload.amount_paid

    travel_back

	end

	test "unconditional payment producer should get paid for successful purchases" do

		assert_equal 0, PaymentPayable.count

		bob = setup_basic_process_through_delivery

    #here, before we process payments, there already should be a payment payable
    #check to make sure it is as expected
    assert_equal 1, PaymentPayable.count
    pp = PaymentPayable.first
    assert_equal 0, pp.amount_paid
    expected_producer_net = 2 * ((1 - (0.035 * 1) - (0.05 * 1)).round(2))
    assert_equal expected_producer_net, pp.amount

    #while we're at it let's make sure the purchase receivable is up to snuff
    assert_equal 1, PurchaseReceivable.count
    pr = PurchaseReceivable.first
    assert_equal 2, pr.amount
    assert_equal 0, pr.amount_purchased
    assert_equal PurchaseReceivable.kind[:NORMAL], pr.kind
    assert_equal PurchaseReceivable.states[:READY], pr.state

    #travel to 10pm so we can process purchases and payments
    now = Time.zone.now
    ten = Time.zone.local(now.year, now.month, now.day, 22, 00)    
    travel_to ten
		RakeHelper.do_hourly_tasks

		#verify purchase went through properly
		assert_equal 2, pr.reload.amount_purchased
    assert_equal PurchaseReceivable.kind[:NORMAL], pr.kind
    assert_equal PurchaseReceivable.states[:COMPLETE], pr.state

    #verify payment went through properly
    assert_equal pp.reload.amount, pp.reload.amount_paid

    travel_back

	end

end