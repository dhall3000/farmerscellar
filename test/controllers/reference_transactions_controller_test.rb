require 'test_helper'

class ReferenceTransactionsControllerTest < ActionController::TestCase
  test "should get create_ba" do
    get :create_ba
    assert_response :success
  end

  test "should get create_capture" do
    get :create_capture
    assert_response :success
  end

end
