require 'integration_helper'

class WebsiteSettingsControllerTest < IntegrationHelper

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
    assert_redirected_to root_url

  	#try to push an update through
  	patch website_setting_path(@website_settings, {website_setting: { new_customer_access_code_required: true }})
  	#verify this attempt was unsuccessful
  	assert_response :redirect

  end

  test "non user cannot update" do

  	#try to get the edit page
  	get_edit
  	#verify unable to get edit page
  	assert_response :redirect

  	#try to push an update through
  	patch website_setting_path(@website_settings, {website_setting: { new_customer_access_code_required: true }})
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
    patch website_setting_path(@website_settings, {website_setting: { new_customer_access_code_required: true, recurring_postings_enabled: true }})
    assert_response :success

    @website_settings.reload    
    assert @website_settings.new_customer_access_code_required
    assert @website_settings.recurring_postings_enabled

    patch website_setting_path(@website_settings, {website_setting: {new_customer_access_code_required: false, recurring_postings_enabled: false}})

    @website_settings.reload
    assert_not @website_settings.new_customer_access_code_required
    assert_not @website_settings.recurring_postings_enabled
    
  end

  def get_edit
    get edit_website_setting_path(@website_settings)
  end

end
