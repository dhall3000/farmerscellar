require 'integration_helper'

class DropsitesControllerTest < IntegrationHelper

  def setup
    @dropsite = dropsites(:dropsite1)
    @user = users(:c1)
    @admin = users(:a1)
  end

  test "should get new" do
    log_in_as(@admin)
    get new_dropsite_path
    assert_response :success
  end

  test "should get index" do
    get dropsites_path
    assert_response :success
  end

  test "should get show" do    
    get dropsite_path(@dropsite)
    assert_response :success
  end

  test "should get edit" do    
    log_in_as(@admin)
    get edit_dropsite_path(@dropsite)
    assert_response :success
  end

end