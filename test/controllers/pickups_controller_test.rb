require 'test_helper'

class PickupsControllerTest < ActionController::TestCase

	def setup
		@customer = users(:c1)
		@admin = users(:a1)
		@farmer = users(:f1)
		@dropsite_user = users(:dropsite1)
	end

  test "should get new" do
  	log_in_as(@dropsite_user)
    get :new
    assert_response :success
    assert_select 'input#pickup_code', count: 1
  end

  test "should not get new when not logged in" do
    get :new
    assert_response :redirect
    assert_select 'input#pickup_code', count: 0
  end

  test "should not get new when logged in as customer" do
    log_in_as(@customer)
    get :new
    assert_response :redirect
    assert_select 'input#pickup_code', count: 0
  end

  test "should not get new when logged in as farmer" do
  	log_in_as(@farmer)
    get :new
    assert_response :redirect
    assert_select 'input#pickup_code', count: 0
  end

  test "should not get new when logged in as admin" do
    log_in_as(@admin)
    get :new
    assert_response :redirect
    assert_select 'input#pickup_code', count: 0
  end

  test "should create" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
  	c1 = users(:c1)
    post :create, pickup_code: c1.pickup_code.code
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert pickup_code.valid?
    user = assigns(:user)
    assert user.valid?
    #a new pickup object should have been created as a result of this pickup action
    assert_equal pickups_count + 1, Pickup.count
    assert_equal c1.id, Pickup.all.last.user_id
  end

  test "should not create when invalid code submitted" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
    post :create, pickup_code: "12A45"
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert_not pickup_code.valid?
    assert_not flash.empty?
    assert_equal "Invalid code entry", flash[:danger]
    assert_equal pickups_count, Pickup.count
  end

  test "should not create when non existent code submitted" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
    post :create, pickup_code: "1345"
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert pickup_code.nil?
    assert_not flash.empty?
    assert_equal "Invalid code entry", flash[:danger]
    assert_equal pickups_count, Pickup.count
  end

end