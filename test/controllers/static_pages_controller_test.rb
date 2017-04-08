require 'integration_helper'

class StaticPagesControllerTest < IntegrationHelper
  test "should get home" do
    get root_path
    assert_response :success
    assert_select "title", "Farmer's Cellar"
  end

  test "should get about" do
  	get about_path
  	assert_response :success
    assert_select "title", "About | Farmer's Cellar"
  end

  test "should get contact" do
    get contact_path
    assert_response :success
    assert_select "title", "Contact | Farmer's Cellar"
  end

end
