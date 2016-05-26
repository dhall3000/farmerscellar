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

	def get_delivery_dates_setup(recurrence_frequency, subscription_frequency)
		@posting_recurrence = PostingRecurrence.new(frequency: recurrence_frequency, on: true)
		@posting_recurrence.postings << postings(:postingf1apples)
		@subscription = Subscription.new(frequency: subscription_frequency, on: true, quantity: 1)
		@subscription.posting_recurrence = @posting_recurrence
		@user = users(:c1)
		@subscription.user = @user

		@posting_recurrence.save
		@subscription.save
		@subscription.generate_next_tote_item
	end

	def verify_posting_recurrence_with_various_frequencies(posting_frequency, subscription_frequency)
		
		get_delivery_dates_setup(posting_frequency, subscription_frequency)

		current_delivery_date = @posting_recurrence.current_posting.delivery_date
		end_date = current_delivery_date + (3 * posting_frequency * subscription_frequency).weeks
		delivery_dates = @subscription.get_delivery_dates(current_delivery_date, end_date)

		assert_equal 3, delivery_dates.count

		assert_equal current_delivery_date + (1 * posting_frequency * subscription_frequency).weeks, delivery_dates[0]
		assert_equal current_delivery_date + (2 * posting_frequency * subscription_frequency).weeks, delivery_dates[1]
		assert_equal current_delivery_date + (3 * posting_frequency * subscription_frequency).weeks, delivery_dates[2]

	end

	def verify_posting_recurrence_five_with_various_subscription_frequencies(subscription_frequency)
		
		posting_frequency = 5
		get_delivery_dates_setup(posting_frequency, subscription_frequency)

		current_delivery_date = @posting_recurrence.current_posting.delivery_date
		end_date = current_delivery_date + (3 * posting_frequency * subscription_frequency).weeks
		delivery_dates = @subscription.get_delivery_dates(current_delivery_date, end_date)

		assert_equal 3, delivery_dates.count
		#assert between 28 - 31 days between postings
		gap = delivery_dates[1] - delivery_dates[0]
		assert gap > (subscription_frequency * 27).days
		assert gap < (subscription_frequency * 39).days

		gap = delivery_dates[2] - delivery_dates[1]
		assert gap > (subscription_frequency * 27).days
		assert gap < (subscription_frequency * 39).days

		#assert all on a friday
		assert_equal 5, delivery_dates[0].wday
		assert_equal 5, delivery_dates[1].wday
		assert_equal 5, delivery_dates[2].wday

	end

	def verify_posting_recurrence_six_with_various_subscription_frequencies(subscription_frequency)
		
		posting_frequency = 6
		get_delivery_dates_setup(posting_frequency, subscription_frequency)

		current_delivery_date = @posting_recurrence.current_posting.delivery_date

		case subscription_frequency
		when 1
			end_date = current_delivery_date + 4.weeks
			delivery_dates = @subscription.get_delivery_dates(current_delivery_date, end_date)
			assert_equal 3, delivery_dates.count

			gap = delivery_dates[0] - current_delivery_date
			assert_equal 1.week, gap
			gap = delivery_dates[1] - delivery_dates[0]
			assert_equal 1.week, gap
			gap = delivery_dates[2] - delivery_dates[1]
			assert_equal 2.weeks, gap

			#assert all on a friday
			assert_equal 5, delivery_dates[0].wday
			assert_equal 5, delivery_dates[1].wday
			assert_equal 5, delivery_dates[2].wday

		when 2
			end_date = current_delivery_date + 6.weeks
			delivery_dates = @subscription.get_delivery_dates(current_delivery_date, end_date)
			assert_equal 3, delivery_dates.count
			
			gap = delivery_dates[0] - current_delivery_date
			assert_equal 2.weeks, gap

			gap = delivery_dates[1] - delivery_dates[0]
			assert_equal 2.weeks, gap

			gap = delivery_dates[2] - delivery_dates[1]
			assert_equal 2.weeks, gap

			#assert all on a friday
			assert_equal 5, delivery_dates[0].wday
			assert_equal 5, delivery_dates[1].wday
			assert_equal 5, delivery_dates[2].wday
		when 3
			end_date = current_delivery_date + 12.weeks
			delivery_dates = @subscription.get_delivery_dates(current_delivery_date, end_date)
			assert_equal 3, delivery_dates.count
			
			gap = delivery_dates[0] - current_delivery_date
			assert_equal 4.weeks, gap

			gap = delivery_dates[1] - delivery_dates[0]
			assert_equal 4.weeks, gap

			gap = delivery_dates[2] - delivery_dates[1]
			assert_equal 4.weeks, gap

			#assert all on a friday
			assert_equal 5, delivery_dates[0].wday
			assert_equal 5, delivery_dates[1].wday
			assert_equal 5, delivery_dates[2].wday
		end

	end

	test "should generate appropriate delivery dates 1 and 1" do
		verify_posting_recurrence_with_various_frequencies(1, 1)
	end

	test "should generate appropriate delivery dates 1 and 2" do
		verify_posting_recurrence_with_various_frequencies(1, 2)
	end

	test "should generate appropriate delivery dates 1 and 3" do
		verify_posting_recurrence_with_various_frequencies(1, 3)
	end

	test "should generate appropriate delivery dates 1 and 4" do
		verify_posting_recurrence_with_various_frequencies(1, 4)
	end

	test "should generate appropriate delivery dates 2 and 1" do
		verify_posting_recurrence_with_various_frequencies(2, 1)
	end

	test "should generate appropriate delivery dates 2 and 2" do
		verify_posting_recurrence_with_various_frequencies(2, 2)
	end	

	test "should generate appropriate delivery dates 2 and 3" do
		verify_posting_recurrence_with_various_frequencies(2, 3)
	end

	test "should generate appropriate delivery dates 2 and 4" do
		verify_posting_recurrence_with_various_frequencies(2, 4)
	end

	test "should generate appropriate delivery dates 3 and 1" do
		verify_posting_recurrence_with_various_frequencies(3, 1)
	end

	test "should generate appropriate delivery dates 3 and 2" do
		verify_posting_recurrence_with_various_frequencies(3, 2)
	end	

	test "should generate appropriate delivery dates 4 and 1" do
		verify_posting_recurrence_with_various_frequencies(4, 1)
	end

	test "should generate appropriate delivery dates 4 and 2" do
		verify_posting_recurrence_with_various_frequencies(4, 2)
	end

	test "should generate appropriate delivery dates 5 and 1" do
		verify_posting_recurrence_five_with_various_subscription_frequencies(1)
	end

	test "should generate appropriate delivery dates 5 and 2" do
		verify_posting_recurrence_five_with_various_subscription_frequencies(2)
	end

	test "should generate appropriate delivery dates 6 and 1" do
		verify_posting_recurrence_six_with_various_subscription_frequencies(1)
	end

	test "should generate appropriate delivery dates 6 and 2" do
		verify_posting_recurrence_six_with_various_subscription_frequencies(2)
	end

	test "should generate appropriate delivery dates 6 and 3" do
		verify_posting_recurrence_six_with_various_subscription_frequencies(3)
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
