require 'test_helper'

class SubscriptionSkipDateTest < ActiveSupport::TestCase

	def setup
		@subscription = Subscription.new(frequency: 1, on: true, quantity: 1)		
		@user = users(:c1)
		@posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
		posting = postings(:postingf1apples)
		@posting_recurrence.postings << posting
		@subscription.user = @user
		@subscription.posting_recurrence = @posting_recurrence				
		@ssd = SubscriptionSkipDate.new(skip_date: Time.zone.now)
		@subscription.subscription_skip_dates << @ssd
	end

	test "should save" do
		assert @ssd.save
		assert @ssd.valid?
	end

	test "should not save without skip_date" do
		@ssd.skip_date = nil
		assert_not @ssd.save
		assert_not @ssd.valid?
	end

	test "should not save without subscription" do
		@ssd.subscription.destroy
		@ssd.subscription = nil
		assert_not @ssd.save
		assert_not @ssd.valid?
	end

end
