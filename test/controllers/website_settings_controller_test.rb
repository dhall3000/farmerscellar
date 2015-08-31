require 'test_helper'

class WebsiteSettingsControllerTest < ActionController::TestCase

  def setup
  	@admin = users(:a1)
  	@customer = users(:c1)  	
  	@website_settings = website_settings(:website_setting_1)
  end

  test "non admin users cannot update" do
  	log_in_as(@customer)

  	#try to get the edit page
  	get_edit
  	#verify unable to get edit page
  	assert_response :redirect

  	#try to push an update through
  	patch :update, id: @website_settings.id, website_setting: { new_customer_access_code_required: true }
  	#verify this attempt was unsuccessful
  	assert_response :redirect

  end

  test "non user cannot update" do

  	#try to get the edit page
  	get_edit
  	#verify unable to get edit page
  	assert_response :redirect

  	#try to push an update through
  	patch :update, id: @website_settings.id, website_setting: { new_customer_access_code_required: true }
  	#verify this attempt was unsuccessful
  	assert_response :redirect

  end

  test "should get edit" do
  	log_in_as(@admin)
  	get_edit
  	assert_response :success
  end

  test "admin can update settings" do
  	log_in_as(@admin)
  	get_edit
  	assert_response :success  	
  	patch :update, id: @website_settings.id, website_setting: { new_customer_access_code_required: true }
  	assert_response :success
  	@website_settings.reload
  	assert @website_settings.new_customer_access_code_required
  	patch :update, id: @website_settings.id, website_setting: {new_customer_access_code_required: false}
  	@website_settings.reload
  	assert_not @website_settings.new_customer_access_code_required
  end

  def get_edit
    get :edit, id: @website_settings.id    
  end

end
