require 'test_helper'

class WebsiteSettingsAccessControlTest < ActionDispatch::IntegrationTest

  def setup
  	@admin = users(:a1)
  	@customer = users(:c1)
  	@farmer = users(:f1)
  	@website_setting = website_settings(:website_setting_1)
  end  

  test "customers without access code have access when code not required" do
  	change_website_access_code_required_to(false)  	
  	verify_user_has_access(@customer)
  end

  test "customers without access code do not have access when code required" do
  	#log in as admin and set website settings to require access code
  	change_website_access_code_required_to(true)

  	#now log in as customer that does not have access code and try to view profile
  	verify_user_has_no_access(@customer)
  end

  test "customers without access gain access when given a code" do
  	change_website_access_code_required_to(true)
  	verify_user_has_no_access(@customer)
  	get_access_for(@customer)
  	verify_user_has_access(@customer)  	
  end

  test "customers with access code always have access" do
  	#get access code for customer
  	get_access_for(@customer)
  	#log in as admin and require code
  	change_website_access_code_required_to(true)
  	#log in as customer and verify access
  	verify_user_has_access(@customer)
  	#log in as admin and unrequire code
  	change_website_access_code_required_to(false)
  	#log in as customer and verify access
  	verify_user_has_access(@customer)  	  	
  end

  def change_website_access_code_required_to(onoff)
  	log_in_as(@admin)
  	patch website_setting_path(@website_setting), website_setting: {new_customer_access_code_required: onoff}
  end

  def verify_user_has_access(user)
  	log_in_as(user)
  	get user_path(user)
  	assert_response :success
  end

  def verify_user_has_no_access(user)
  	log_in_as(user)
  	get user_path(user)
  	assert_response :redirect
  end

  def verify_farmer_access_changes_with_code
  	verify_user_has_no_access(@farmer)
  	get_access_for(@farmer)
  	verify_user_has_access(@farmer)
  end

  test "producers without access code never have access" do
  	change_website_access_code_required_to(true)
  	verify_user_has_no_access(@farmer)  	
  	change_website_access_code_required_to(false)
  	verify_user_has_no_access(@farmer)
  end

  test "farmers without access gain access when given a code 1" do
  	change_website_access_code_required_to(true)
  	verify_farmer_access_changes_with_code
  end

  test "farmers without access gain access when given a code 2" do
  	change_website_access_code_required_to(false)
  	verify_farmer_access_changes_with_code
  end

end