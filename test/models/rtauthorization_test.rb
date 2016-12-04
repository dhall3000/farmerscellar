require 'test_helper'

class RtauthorizationTest < ActiveSupport::TestCase

	def setup
		@rtba = rtbas(:one)
		@rtauthorization = Rtauthorization.new(rtba_id: @rtba.id)
		@tote_item = tote_items(:c1apple)
		@rtauthorization.tote_items << @tote_item
	end

	test "authorized works right" do		
		assert @rtauthorization.save
		assert @rtauthorization.authorized?
		@rtba.update(active: false)
		@rtauthorization.reload
		assert_not @rtauthorization.authorized?
	end

	test "should deauthorize" do

		#move the ti state to auth'd
		@tote_item.update(state: ToteItem.states[:AUTHORIZED])
		#verify ti state is auth'd
		assert @tote_item.state?(:AUTHORIZED)		
		#call rtauth.deauth
		@rtauthorization.deauthorize
		#verify ti is deauth'd
		assert @tote_item.state?(:ADDED)		

	end

	test "should not deauthorize toteitems" do

		#move the ti state to committed
		@tote_item.transition(:customer_authorized)
		@tote_item.transition(:order_cutoffed)
		#verify ti state is committed
		assert @tote_item.state?(:COMMITTED)		
		#call rtauth.deauth
		@rtauthorization.deauthorize
		#verify ti is not deauth'd
		assert_not @tote_item.state?(:ADDED)		

	end

	test "should save" do
		assert @rtauthorization.save
		assert @rtauthorization.valid?
	end

	test "should not save without billing agreement reference" do
		@rtauthorization.rtba_id = nil
		assert_not @rtauthorization.save
		assert_not @rtauthorization.valid?
	end

	test "should not save without at least one tote item" do
		@rtauthorization.tote_items.delete(@tote_item)
		assert_not @rtauthorization.save
		assert_not @rtauthorization.valid?
	end

	test "should add tote items and subscriptions and transition tote items too" do

    user = users(:c1)
    rtba = Rtba.new(token: "token", ba_id: "ba_id", active: true)
    rtba.user = user
    assert rtba.valid?
    assert rtba.save
    #add a subscription and generate a toteitem off of it
    add_subscription_and_item_to_c1

    #how many ADDED items do we have?
    num_added_items = user.tote_items.where(state: ToteItem.states[:ADDED]).count
    #we should have at least 1
    assert num_added_items > 0
    #now transition the 1st item to COMMITTED
    user.tote_items.first.update(state: ToteItem.states[:COMMITTED])
    #and now the number of ADDED items should have gone down by 1
    assert num_added_items - 1, user.tote_items.where(state: ToteItem.states[:ADDED]).count

    #verify subscription is not authorized
    subscriptions = get_active_subscriptions_for(user)
    assert_equal 1, subscriptions.count

    assert_not subscriptions.last.authorized?
    
    rtauthorization = Rtauthorization.new(rtba: rtba)    
    rtauthorization.authorize_items_and_subscriptions(user.tote_items, subscriptions)
    assert rtauthorization.valid?
    assert rtauthorization.save

    assert subscriptions.last.authorized?
    assert_equal ToteItem.states[:COMMITTED], user.tote_items.first.state
    assert_equal ToteItem.states[:AUTHORIZED], user.tote_items.last.state
		
	end

	test "should not authorize tote items if self not authorized" do
    user = users(:c1)
    rtba = Rtba.new(token: "token", ba_id: "ba_id", active: false)
    rtba.user = user
    assert rtba.valid?
    assert rtba.save
    #add a subscription and generate a toteitem off of it
    add_subscription_and_item_to_c1

    #how many ADDED items do we have?
    num_added_items = user.tote_items.where(state: ToteItem.states[:ADDED]).count
    #we should have at least 1
    assert num_added_items > 0
    #now transition the 1st item to COMMITTED
    user.tote_items.first.update(state: ToteItem.states[:COMMITTED])
    #and now the number of ADDED items should have gone down by 1
    assert num_added_items - 1, user.tote_items.where(state: ToteItem.states[:ADDED]).count

    #verify subscription is not authorized    
    subscriptions = get_active_subscriptions_for(user)
    assert_equal 1, subscriptions.count

    assert_not subscriptions.last.authorized?
    
    rtauthorization = Rtauthorization.new(rtba: rtba)    
    rtauthorization.authorize_items_and_subscriptions(user.tote_items, subscriptions)

    #should not be valid because the above .authorize_items_and_subscriptions should have accomplished nothing
    #because the rtauth isn't authorized because the rtba is not active
    assert_not rtauthorization.valid?, rtauthorization.errors.full_messages
    assert_not rtauthorization.save

    #verify no state changed
    assert_not subscriptions.last.authorized?    
    assert_equal ToteItem.states[:COMMITTED], user.tote_items.first.state
    assert_equal ToteItem.states[:ADDED], user.tote_items.last.state

	end

  def add_subscription_and_item_to_c1
    posting_recurrence = posting_recurrences(:one)
    subscription = Subscription.new(frequency: 1, on: true, user: users(:c1), posting_recurrence: posting_recurrence, quantity: 2)
    subscription.save
    subscription.generate_next_tote_item
  end

end
