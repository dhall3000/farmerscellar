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

  test "should get create" do
    #get :create
    #assert_response :success
  end

	test "should give helpful error text on invalid input" do
	end

end