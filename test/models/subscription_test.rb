require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

	def setup
		@posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
		@posting_recurrence.postings << postings(:postingf1apples)
		@subscription = Subscription.new(frequency: 1, on: true, quantity: 1)
		@subscription.posting_recurrence = @posting_recurrence
		@user = users(:c1)
		@subscription.user = @user

		@posting_recurrence.save
		@subscription.save
	end

	test "should generate new added tote item when rtauthorization is inactive" do
		#create new billing agreement
		rtba = Rtba.new(token: "faketoken", ba_id: "fake_ba_id", user_id: @user.id, active: true)
		assert rtba.save
		#create new rtauthorization
		rtauthorization = Rtauthorization.new(rtba_id: rtba.id)
		#we need to add at least one tote item to the auth before saving to get around the validation
		rtauthorization.tote_items << @user.tote_items.first
		rtauthorization.subscriptions << @subscription
		assert rtauthorization.save, rtauthorization.errors.messages

		assert rtba.active
		assert rtauthorization.authorized?
		assert @subscription.authorized?

		rtba.deactivate
		assert_not rtba.active
		rtauthorization.reload
		assert_not rtauthorization.authorized?
		assert_not @subscription.authorized?

		generate_new_tote_item
		assert @subscription.tote_items.last.state?(:ADDED)
	end

	test "should generate new added tote item when rtauthorization is nil" do
		#create new billing agreement. this isn't really necessary, just a relic of copy/paste and leaving it here for the fun of it
		rtba = Rtba.new(token: "faketoken", ba_id: "fake_ba_id", user_id: @user.id, active: true)
		assert rtba.save

		assert @subscription.on
		assert_not @subscription.rtauthorizations.any?

		generate_new_tote_item
		assert @subscription.tote_items.last.state?(:ADDED)
	end

	test "should generate new authorized tote item when rtauthorization is legit" do
		#create new billing agreement
		rtba = Rtba.new(token: "faketoken", ba_id: "fake_ba_id", user_id: @user.id, active: true)
		assert rtba.save
		#create new rtauthorization
		rtauthorization = Rtauthorization.new(rtba_id: rtba.id)
		#we need to add at least one tote item to the auth before saving to get around the validation
		rtauthorization.tote_items << @user.tote_items.first
		rtauthorization.subscriptions << @subscription
		assert rtauthorization.save, rtauthorization.errors.messages

		generate_new_tote_item
		assert @subscription.tote_items.last.state?(:AUTHORIZED)
	end

	test "should provide correct description" do
		@subscription.quantity = 2
		@subscription.frequency = 2
		@subscription.save
		assert_match "2 Pounds of F1 FARM Fuji Apples delivered every 2 weeks for a subtotal of $5.50 each delivery",	@subscription.description
	end

	test "should not generate new tote item when off" do
		assert @subscription.on
		assert @posting_recurrence.subscribable?
		@subscription.turn_off
		assert_not @subscription.on
		assert @subscription.valid?
		assert_equal 0, @subscription.tote_items.count
		tote_item = @subscription.generate_next_tote_item
		assert_not tote_item
		assert_equal 0, @subscription.tote_items.count		
	end

	test "should not generate new tote item when posting recurrence is off" do
		assert @subscription.on
		assert @posting_recurrence.subscribable?
		@posting_recurrence.turn_off
		assert_not @posting_recurrence.subscribable?
		@subscription.reload

		#turning off the posting recurrence should have turned off the subscriptions
		assert_not @subscription.on

		#as of now (2016-05-12) once a subscription is turned off it can't be turned on
		#so this next line of code is wonky. but still want to make sure that if a pr
		#is off and a sx is on that the sx won't generate a new tote item
		@subscription.update(on: true)
		assert @subscription.on

		assert @subscription.valid?
		assert_equal 0, @subscription.tote_items.count
		tote_item = @subscription.generate_next_tote_item
		assert_not tote_item
		assert_equal 0, @subscription.tote_items.count				
	end

	test "should generate new tote item" do
		generate_new_tote_item
	end

	test "should not generate new tote item on immediateley successive calls" do
		generate_new_tote_item
		assert_equal 1, @subscription.tote_items.count
		assert_equal nil, @subscription.generate_next_tote_item
		assert_equal 1, @subscription.tote_items.count
	end

	def generate_new_tote_item
		assert @subscription.valid?
		assert_equal 0, @subscription.tote_items.count
		tote_item = @subscription.generate_next_tote_item
		assert tote_item.valid?
		assert_equal 1, @subscription.tote_items.count
		if @subscription.authorized?
			assert @subscription.tote_items.last.state?(:AUTHORIZED)
		else			
			assert @subscription.tote_items.last.state?(:ADDED)
		end
		
	end

	test "should save" do
		assert @subscription.save
		assert @subscription.valid?
	end

	test "should not save without frequency" do
		@subscription.frequency = nil
		assert_not @subscription.save
		assert_not @subscription.valid?
	end

	test "should not save with negative frequency value" do
		@subscription.frequency = -1
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with float frequency value" do
		@subscription.frequency = 1.5
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save without posting_recurrence" do		
		@subscription.posting_recurrence.destroy
		@subscription.posting_recurrence = nil
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save without user" do		
		@subscription.user.destroy
		@subscription.user = nil
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save without quantity" do
		@subscription.quantity = nil
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with negative quantity" do
		@subscription.quantity = -1
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with zero quantity" do
		@subscription.quantity = 0
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

end
