require 'test_helper'

class RtauthorizationsControllerTest < ActionController::TestCase

	def setup
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

end