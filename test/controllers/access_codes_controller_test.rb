require 'test_helper'

class AccessCodesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @a1 = users(:a1)    
  end

  test "should get new" do
    log_in_as(@a1)
    get new_access_code_path
    assert_response :success
  end

  test "should get create" do
    log_in_as(@a1)        
    post access_codes_path, params: {access_code: {notes: "hello"}}
    assert_response :success
  end

end