require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

	def setup
		@subscription = Subscription.new(interval: 1, on: true, quantity: 1, price: 2.50)
		@posting_recurrence = PostingRecurrence.new(interval: 1, on: true)
		@subscription.posting_recurrence = @posting_recurrence
		@user = users(:c1)
		@subscription.user = @user
	end

	test "should save" do
		assert @subscription.save
		assert @subscription.valid?
	end

	test "should not save without interval" do
		@subscription.interval = nil
		assert_not @subscription.save
		assert_not @subscription.valid?
	end

	test "should not save with negative interval value" do
		@subscription.interval = -1
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with float interval value" do
		@subscription.interval = 1.5
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

	test "should not save without price" do
		@subscription.price = nil
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with negative price" do
		@subscription.price = -1.2
		assert_not @subscription.save
		assert_not @subscription.valid?		
	end

	test "should not save with zero price" do
		@subscription.price = 0
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
