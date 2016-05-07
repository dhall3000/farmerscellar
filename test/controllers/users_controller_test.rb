require 'test_helper'

class UsersControllerTest < ActionController::TestCase

  def setup
    @admin = users(:a1)
    @user = users(:c1)
    @other_user = users(:c2)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not get show for a different customer" do
    log_in_as(@user)
    other_user = users(:c2)
    WebsiteSetting.create(new_customer_access_code_required: false, recurring_postings_enabled: true)
    get :show, id: other_user
    assert :redirect
  end

  test "should get show for farmer when logged in as admin" do
    log_in_as(@admin)
    other_user = users(:f1)
    WebsiteSetting.create(new_customer_access_code_required: false, recurring_postings_enabled: true)
    get :show, id: other_user
    assert :success
  end

  test "should redirect edit when not logged in" do
    get :edit, id: @user
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect update when not logged in" do
    post :update, id: @user, user: { name: @user.name, email: @user.email }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect edit when logged in as wrong user" do
    log_in_as(@other_user)
    get :edit, id: @user
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect update when logged in as wrong user" do
    log_in_as(@other_user)
    patch :update, id: @user, user: { name: @user.name, email: @user.email }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect index when not logged in" do
    get :index
    assert_redirected_to login_url
  end
  
end