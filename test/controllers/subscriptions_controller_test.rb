require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase

  def setup
    @c1 = users(:c1)
    @c_subscription = users(:c_subscription)
    @subscription = subscriptions(:one)
  end

  test "should get index when user logged in" do
    log_in_as(@c1)
    get :index
    assert_response :success
    assert_template 'subscriptions/index'
  end

  test "should not get index when user not logged in" do    
    get :index
    assert_response :redirect    
    assert_redirected_to login_path
  end

  test "index should tell user when they have no subscriptions" do
    assert_equal 0, @c1.subscriptions.count
    log_in_as(@c1)
    get :index
    assert_response :success
    assert_template 'subscriptions/index'
    assert_select 'p', "You do not have any subscriptions"
    assert_equal false, assigns(:subscriptions).any?
    assert_equal nil, assigns(:end_date)
    assert_equal nil, assigns(:skip_dates)
  end

  test "should not get show when user not logged in" do
    get :show, id: @subscription.id
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should get show when user logged in" do
    log_in_as(@c_subscription)
    get :show, id: @subscription.id
    assert_response :success
    assert_template 'subscriptions/show'

    subscriptions = assigns(:subscriptions)    
    assert_equal 1, subscriptions.count
    sub = subscriptions.last
    assert sub.on
    assert_equal 1, sub.frequency

    skip_dates = assigns(:skip_dates)
    assert_equal 0, skip_dates.count
  end

  test "should not get edit when user not logged in" do
    get :edit, id: @subscription.id
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should get edit when user logged in" do
    log_in_as(@c_subscription)
    get :edit, id: @subscription.id
    assert_response :success
    assert_template 'subscriptions/edit'

    subscriptions = assigns(:subscriptions)    
    assert_equal 1, subscriptions.count
    sub = subscriptions.last
    assert sub.on
    assert_equal 1, sub.frequency

    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 0
  end
  
  #have no sx
  #have one sx
  #have many sx
  #have no sd
  #have 1 sd
  #have many sd
  #remove 1 sd
  #remove all sd
  #test security


  test "should get show" do
#    get :show
#    assert_response :success
  end

  test "should get edit" do
#    get :edit
#    assert_response :success
  end

  test "should get update" do
#    get :update
#    assert_response :success
  end

end
