require 'integration_helper'

class SubscriptionAuthorizationTest < IntegrationHelper

	test "subsequent subscription should end up on same authorization as existing subscription" do

		#set up the 1st subscription. doing this generates bob's 1st rtauthorization
		bob = setup_basic_subscription_through_delivery
		assert_equal 1, bob.rtbas.count
		assert_equal 1, bob.rtbas.first.rtauthorizations.count

		#nuke the tote item associated with this subscription
		assert_equal 2, bob.tote_items.count
		assert_equal ToteItem.states[:FILLED], bob.tote_items.first.state
		assert_equal ToteItem.states[:AUTHORIZED], bob.tote_items.last.state
		log_in_as(bob)		
		ti = bob.tote_items.last		
		delete tote_item_path(ti)

		#verify the tote item nuke took effect
		assert_equal 2, bob.tote_items.count
		assert_equal ToteItem.states[:FILLED], bob.tote_items.first.state
		assert_equal ToteItem.states[:REMOVED], bob.tote_items.last.state

		#at this point bob doesn't have any items in his tote, although he does have an authorized subscription

		#create another subscription
    create_tote_item(bob, Posting.last, 2, subscription_frequency = 1)
    assert_equal 3, Rtauthorization.count
    rtauth1 = Rtauthorization.last

    #authorize this 2nd subscription
    rtauthorization = create_rt_authorization_for_customer(bob)
    rtauth2 = Rtauthorization.last

    #at this point bob should have two subscription and they should both be using the same authorization so
    #that we're only making one paypal pull at a time
    assert_equal 2, bob.subscriptions.count
    sx1 = bob.subscriptions.first
    sx2 = bob.subscriptions.last

    assert_equal sx1.rtauthorizations.last.id, sx2.rtauthorizations.last.id

    travel_back

	end

end