require 'test_helper'

class RtbaTest < ActiveSupport::TestCase

	def setup
		@user = users(:c1)
		@rtba = Rtba.new(token: "faketoken", ba_id: "fake_ba_id", user_id: @user.id, active: true)

		@rtba.save

		@posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
		@posting_recurrence.postings << postings(:postingf1apples)
		@posting_recurrence.save

		@subscription = Subscription.new(frequency: 1, on: true, quantity: 1)
		@subscription.posting_recurrence = @posting_recurrence
		@subscription.user = @user				
		@subscription.save		
		
		@rtauthorization = Rtauthorization.new(rtba: @rtba)		
		@rtauthorization.subscriptions << @subscription				
		tote_item = @subscription.generate_next_tote_item
		@rtauthorization.tote_items << tote_item
		@subscription.save
		@rtauthorization.save		
		@rtba.save

	end

	test "billing agreement should be valid" do
		assert @rtba.ba_valid?
	end

	test "billing agreement should be invalid because not active" do
		assert @rtba.active
		assert @rtba.ba_valid?
		@rtba.update(active: false)
		assert_not @rtba.active
		assert_not @rtba.ba_valid?		
	end

	test "billing agreement should be invalid because paypal says so" do
		assert @rtba.active
		assert @rtba.ba_valid?
		#set param to fail
		@rtba.test_params = "failure"
		assert_not @rtba.ba_valid?	
		assert_not @rtba.active		
	end

	test "should deauthorize rtauthorizations when paypal says billing agreement is inactive" do
		#verify rtba has at least one rtauthorization
		assert_equal 1, @rtba.rtauthorizations.count
		#verify rtauth has at least one authorized toteitem
		assert_equal 1, @rtba.rtauthorizations.last.tote_items.count
		ti = @rtba.rtauthorizations.last.tote_items.last
		ti.update(state: ToteItem.states[:AUTHORIZED])
		assert_equal ToteItem.states[:AUTHORIZED], ti.state
		#verify rtauth has at least one authorized subscription
		assert @rtba.rtauthorizations.last.subscriptions.last.authorized?
		assert @rtba.active
		assert @rtba.ba_valid?
		#set param to fail
		@rtba.test_params = "failure"
		assert_not @rtba.ba_valid?	
		assert_not @rtba.active
		#verify previously auth'd tote item is now in the ADDED state
		assert ToteItem.states[:ADDED], ti.state
		#verify previously auth'd subscription is no longer auth'd
		assert_not @rtba.rtauthorizations.last.subscriptions.last.authorized?
		#verify rtauth is now deauth'd
		assert_not @rtba.rtauthorizations.last.authorized?		
	end

	test "should save" do
		assert @rtba.save
		assert @rtba.valid?
	end

	test "should not save without token" do
		@rtba.token = nil
		assert_not @rtba.save
		assert_not @rtba.valid?
	end

	test "should not save without ba_id" do
		@rtba.ba_id = nil
		assert_not @rtba.save
		assert_not @rtba.valid?		
	end

	test "should not save without user" do
		@rtba.user_id = nil
		assert_not @rtba.save
		assert_not @rtba.valid?		
	end

end
