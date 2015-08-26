require 'test_helper'

class BulkPaymentsControllerTest < ActionController::TestCase

  def setup
  	@a1 = users(:a1)
  end

  test "should get new" do
  	log_in_as(@a1)
    get :new
    assert_response :success
  end

  test "should redirect on get new" do
    get :new
    assert_response :redirect
  end

  test "should redirect on get create" do
    post :create
    assert_response :redirect
  end

  test "should get create" do
  	log_in_as(@a1)
  	post :create
  	assert_response :success
  end

end
