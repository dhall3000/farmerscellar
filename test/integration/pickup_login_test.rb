require 'test_helper'

class PickupLoginTest < ActionDispatch::IntegrationTest

	def setup
    @user = users(:c1)
    @other_user = users(:c2)    
    @dropsite_user = users(:dropsite1)
  end

  test "dropsite user should log in" do    
    log_in_as(@dropsite_user)
    assert :success
  end

  test "should get pickup login page when logging in as dropsite user" do
    log_in_as(@dropsite_user)
    assert :success
    assert_redirected_to new_pickup_path
    follow_redirect!
    assert_template 'pickups/new'
  end

end