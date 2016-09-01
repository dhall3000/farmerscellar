require 'test_helper'

class AuthorizationsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:c1)    
  end

  test "should get new" do
  	log_in_as @user
    get new_authorization_path, params: {token: "toke"}
    assert_response :success
    assert_template 'authorizations/new'
  end

end