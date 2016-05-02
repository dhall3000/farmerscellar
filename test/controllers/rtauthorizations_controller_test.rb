require 'test_helper'

class RtauthorizationsControllerTest < ActionController::TestCase

	def setup
		@c1 = users(:c1)
	end

	test "should get new" do
		log_in_as(users(:c1))
		#the 'success' flag is strictly for test to force the type of paypal spoof response
		get :new, token: "token", success: true
		assert :success
		assert_template 'rtauthorizations/new'
		assert assigns(:token)
		assert assigns(:tote_items_authorizable)
		assert flash[:success].nil?
		assert flash[:danger].nil?
	end

	#should not get new because response from paypal is not success
	test "should not get new" do
		log_in_as(users(:c1))
		assert_equal 0, ActionMailer::Base.deliveries.count
		#the 'success' flag is strictly for test to force the type of paypal spoof response
		get :new, token: "token", success: false
		assert :redirect
		assert_redirected_to tote_items_path
		assert_not flash[:danger].empty?
		assert flash[:success].nil?		
		assert flash.now[:success].nil?
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "User billing agreement signup failure!", "success: false")
	end

	test "should show authorization of part of the tote" do
		c1 = users(:c1)
		log_in_as(c1)
		posting_recurrence = posting_recurrences(:one)
		subscription = Subscription.new(frequency: 1, on: true, user: @c1, posting_recurrence: posting_recurrence, quantity: 2)
		subscription.save
		subscription.generate_next_tote_item

		i = 0
		num_items_already_authorized = 5
		while i < num_items_already_authorized
			c1.tote_items[i].update(state: 1)
			i += 1
		end

		get :new, token: "token", success: true
		tote_items_authorizable = assigns(:tote_items_authorizable)
		token = assigns(:token)

		assert_equal c1.tote_items.count - num_items_already_authorized, tote_items_authorizable.count
		assert_not token.nil?

	end

end