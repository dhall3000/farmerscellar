require 'test_helper'

class PostingsControllerTest < ActionController::TestCase
  test "should get edit" do
    post :edit
    assert_response :success
  end

end
