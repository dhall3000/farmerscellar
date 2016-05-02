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

	test "should provide correct description" do
		@subscription.quantity = 2
		@subscription.frequency = 2
		@subscription.save
		assert_match "2 Pounds of F1 FARM Fuji Apples delivered every 2 weeks for a subtotal of $5.50 each delivery",	@subscription.description
	end

	test "should not generate new tote item when off" do
		assert @subscription.on
		@subscription.turn_off
		assert_not @subscription.on
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
		assert_equal ToteItem.states[:ADDED], @subscription.tote_items.last.state
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
