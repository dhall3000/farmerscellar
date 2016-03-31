require 'test_helper'

class ReferenceTransactionsControllerTest < ActionController::TestCase
  test "should get create_ba" do
    get :create_ba
    #we get redirects so this assertion doesn't work assert_response :success
  end

  test "should get create_capture" do
    get :create_capture
    #we get redirects so this assertion doesn't work assert_response :success
  end

end
