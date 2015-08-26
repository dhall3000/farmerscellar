require 'test_helper'

class AccessCodesControllerTest < ActionController::TestCase

  def setup
    @a1 = users(:a1)    
  end

  test "should get new" do
    log_in_as(@a1)
    get :new
    assert_response :success
  end

  test "should get create" do
    log_in_as(@a1)        
    post :create, access_code: {notes: "hello"}
    assert_response :success
  end

  #test "should get update" do
  #  patch :update
  #  assert_response :success
  #end

end
