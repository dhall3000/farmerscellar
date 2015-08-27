require 'test_helper'

class PostingsControllerTest < ActionController::TestCase

  def setup
  	@user = users(:f1)
  	@posting = postings(:postingf1apples)
  end

  test "should get redirected if not logged in" do  	
    get :edit, id: @posting
    assert_not flash.empty?
    assert_redirected_to login_url    
  end

  test "should get new" do
  	return
    get :new
    assert_response :success
  end

  test "should redirect edit when not logged in" do
  	return
    get :edit, id: @user
    assert_not flash.empty?
    assert_redirected_to login_url
  end

end
