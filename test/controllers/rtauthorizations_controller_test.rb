require 'integration_helper'

class RtauthorizationsControllerTest < IntegrationHelper

	def setup
		@c1 = users(:c1)
		@c2 = users(:c2)
		ActionMailer::Base.deliveries.clear
	end

	test "should get new" do
		log_in_as(users(:c1))
		#the 'success' flag is strictly for test to force the type of paypal spoof response
		get rtauthorizations_new_path, params: {token: "token"}
		assert :success
		assert_template 'rtauthorizations/new'
		assert assigns(:token)
		assert assigns(:tote_items)
		assert flash[:success].nil?
		assert flash[:danger].nil?
	end

	#should not get new because response from paypal is not success
	test "should not get new" do
		log_in_as(users(:c1))
		assert_equal 0, ActionMailer::Base.deliveries.count
		#the 'success' flag is strictly for test to force the type of paypal spoof response
		get rtauthorizations_new_path, params: {token: "token", testparam_fail_fakedetailsfor: true}
		assert :redirect
		assert_redirected_to tote_items_path
		assert_not flash[:danger].empty?
		assert flash[:success].nil?		
		assert flash.now[:success].nil?
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "User billing agreement signup failure!", "success: false")
	end

	test "should show authorization of part of the tote" do
		log_in_as(@c1)
		add_subscription_and_item_to_user(@c1)
		authorize_part_of_tote(@c1)
		get rtauthorizations_new_path, params: {token: "token"}
		tote_items = assigns(:tote_items)
		token = assigns(:token)
		assert tote_items.count > 0
		assert tote_items.count < @c1.tote_items.count
		assert_not token.nil?

	end

	test "should notify admin and user if billing agreement establishment fails" do
		log_in_as(@c1)		
		add_subscription_and_item_to_user(@c1)
		assert_equal 0, ActionMailer::Base.deliveries.count
		post rtauthorizations_create_path, params: {token: "token", testparam_fail_fakestore: true}
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "Problem creating paypal billing agreement!", "success: false")		
		assert_not flash.empty?
		assert_equal "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us.", flash.now[:danger]
		assert_redirected_to tote_items_path
	end

	test "should notify admin and user if rtba creation fails" do
		log_in_as(@c1)		
		add_subscription_and_item_to_user(@c1)
		assert_equal 0, ActionMailer::Base.deliveries.count
		post rtauthorizations_create_path, params: {token: "token", testparam_fail_rtba_creation: true}
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "Problem creating rtba!", "can't be blank")
		assert_not flash.empty?
		assert_equal "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us.", flash.now[:danger]
		assert_redirected_to tote_items_path
	end

	test "should notify admin and user if billing agreement invalid" do
		log_in_as(@c1)		
		add_subscription_and_item_to_user(@c1)
		assert_equal 0, ActionMailer::Base.deliveries.count
		post rtauthorizations_create_path, params: {token: "token", testparam_fail_rtba_invalid: true}
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "Billing agreement invalid!", "fakebillingagreementid")
		assert_not flash.empty?
		assert_equal "The Billing Agreement we have on file is no longer valid. Please try to establish a new one by checking out again. If you continue to have problems please contact us.", flash.now[:danger]
		assert_redirected_to tote_items_path
	end

	test "should not create if rtauthorization does not save" do		

		log_in_as(@c1)
		add_subscription_and_item_to_user(@c1)
		authorize_part_of_tote(@c1)

		#verify subscription exists
		subscriptions = ToteItemsController.helpers.get_active_subscriptions_for(@c1)
		assert_equal 1, subscriptions.count
		#verify no items or subscriptions associated with rtauth
		@c1.tote_items.each do |tote_item|
			assert_equal 0, tote_item.rtauthorizations.count
		end

		assert_equal 0, subscriptions[0].rtauthorizations.count
		assert_equal 0, ActionMailer::Base.deliveries.count

		post rtauthorizations_create_path, params: {token: "token", testparam_fail_rtauthsave: true}

		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "Problem saving Rtauthorization!", "can't be blank")

		#verify all items and subscriptions associated with rtauth
		rtauthorization = assigns(:rtauthorization)
		assert_not rtauthorization.nil?

		@c1.tote_items.each do |tote_item|
			assert_equal 0, tote_item.rtauthorizations.count
		end

		assert_equal 0, subscriptions[0].rtauthorizations.count
		assert_equal "Checkout successful", flash.now[:success]

	end

	test "should not authorize off billing agreement belonging to another user" do
		log_in_as(@c2)
		add_subscription_and_item_to_user(@c2)
		#verify subscription exists		
		subscriptions = ToteItemsController.helpers.get_active_subscriptions_for(@c2)
		assert_equal 1, subscriptions.count
		#verify no items or subscriptions associated with rtauth
		@c2.tote_items.each do |tote_item|
			assert_equal 0, tote_item.rtauthorizations.count
		end

		assert_equal 0, subscriptions[0].rtauthorizations.count

		#this token is in the rtba yml file and belongs to c1 so this post operation should fail
		#because we're trying to authorize a tote full of c2's items off of c1's billing agreement
		post rtauthorizations_create_path, params: {token: "faketoken"}

		#verify rtauthorization is nil
		rtauthorization = assigns(:rtauthorization)
		assert rtauthorization.nil?
		#verify flash
		assert_equal "Checkout failed. Please try again or contact us if this continues.", flash[:danger]		
		#verify redirect
		assert_redirected_to tote_items_path
		#verify admin email
		assert_equal 1, ActionMailer::Base.deliveries.count
		assert_appropriate_email(ActionMailer::Base.deliveries[0], "david@farmerscellar.com", "Billing agreement hack potential!", "rtba.user.id")		
	end

	test "create should stamp all items and subscriptions with rtauthorization" do		

		log_in_as(@c1)
		add_subscription_and_item_to_user(@c1)
		authorize_part_of_tote(@c1)

		#verify subscription exists		
		subscriptions = ToteItemsController.helpers.get_active_subscriptions_for(@c1)
		assert_equal 1, subscriptions.count
		#verify no items or subscriptions associated with rtauth
		@c1.tote_items.each do |tote_item|
			assert_equal 0, tote_item.rtauthorizations.count
		end

		assert_equal 0, subscriptions[0].rtauthorizations.count

		post rtauthorizations_create_path, params: {token: "token"}

		#verify all items and subscriptions associated with rtauth
		rtauthorization = assigns(:rtauthorization)
		assert_not rtauthorization.nil?

		@c1.tote_items.each do |tote_item|
			assert_equal rtauthorization.id, tote_item.rtauthorizations.last.id
		end

		assert_equal rtauthorization.id, subscriptions[0].rtauthorizations.last.id
		assert_equal "Checkout successful", flash.now[:success]

	end

	def add_subscription_and_item_to_user(user)
		posting_recurrence = posting_recurrences(:one)
		subscription = Subscription.new(frequency: 1, on: true, user: user, posting_recurrence: posting_recurrence, quantity: 2)
		subscription.save
		subscription.generate_next_tote_item
	end

	def authorize_part_of_tote(user)
		i = 0
		num_items_already_authorized = user.tote_items.count / 2
		while i < num_items_already_authorized
			user.tote_items[i].update(state: 1)
			i += 1
		end		
	end

end