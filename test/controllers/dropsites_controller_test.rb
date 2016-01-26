require 'test_helper'

class DropsitesControllerTest < ActionController::TestCase

  def setup
    @dropsite = dropsites(:dropsite1)
    @user = users(:c1)
    @admin = users(:a1)
  end

  test "should get new" do
    log_in_as(@admin)
    get :new
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do    
    get :show, id: @dropsite
    assert_response :success
  end

  test "should get edit" do    
    log_in_as(@admin)
    get :edit, id: @dropsite
    assert_response :success
  end

end
