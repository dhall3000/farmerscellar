require 'test_helper'

class AuthorizationsControllerTest < ActionController::TestCase

  def setup
    @user = users(:c1)    
  end

  test "should get new" do
  	log_in_as @user
    get :new, token: "toke"
    assert_response :success
    assert_template 'authorizations/new'
  end

  #test "should get create" do
  #  get :create
  #  assert_response :success
  #end

end
