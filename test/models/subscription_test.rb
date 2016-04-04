require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

	def setup
		@subscription = Subscription.new(frequency: 1, on: true, quantity: 1)
		@posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
		@subscription.posting_recurrence = @posting_recurrence
		@user = users(:c1)
		@subscription.user = @user
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
