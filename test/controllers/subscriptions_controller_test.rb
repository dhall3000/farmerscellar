require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase

  def setup
    @c1 = users(:c1)
    @c_subscription = users(:c_subscription)
    @subscription = subscriptions(:one)
  end

  test "should create" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    subscription_count = @c1.subscriptions.count
    post :create, tote_item_id: ti.id, frequency: 1
    assert_response :redirect    
    assert_redirected_to postings_path    
    @c1.reload
    assert_equal subscription_count + 1, @c1.subscriptions.count
    assert_not flash.empty?
    assert_equal "Subscription created", flash.now[:success]
    subscription = assigns(:subscription)
    assert_equal 1, subscription.tote_items.count
    assert_equal @c1.id, subscription.tote_items.last.user.id
  end

  test "should not create subscription when frequency is 0" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    subscription_count = @c1.subscriptions.count
    post :create, tote_item_id: ti.id, frequency: 0
    assert_response :redirect    
    assert_redirected_to postings_path
    assert_not flash.empty?
    assert_equal "Tote item created", flash[:success]
    @c1.reload
    assert_equal subscription_count, @c1.subscriptions.count
  end

  test "should not create when posting recurrence is off" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_off)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    post :create, tote_item_id: ti.id, frequency: 1
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not create when posting does not recur" do
    log_in_as(@c1)
    c1apple = tote_items(:c1apple)
    assert c1apple.valid?
    post :create, tote_item_id: c1apple.id, frequency: 1
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not create when frequency not in recurrence options" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    post :create, tote_item_id: ti.id, frequency: 100
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when frequency not in params" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    post :create, tote_item_id: ti.id
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when user not logged in" do
    post :create
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should not create when tote item id not in params" do
    log_in_as(@c1)
    post :create
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when tote item id does not belong to current user" do
    log_in_as(@c1)
    t18 = tote_items(:t18)
    assert t18.valid?
    post :create, tote_item_id: t18.id
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should get new" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    get :new, tote_item_id: ti.id
    assert_response :success
    assert_template 'subscriptions/new'
  end

  test "should not get new when posting recurrence is off" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_off)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    get :new, tote_item_id: ti.id
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when posting does not recur" do
    log_in_as(@c1)
    c1apple = tote_items(:c1apple)
    assert c1apple.valid?
    get :new, tote_item_id: c1apple.id
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when tote item id does not belong to current user" do
    log_in_as(@c1)
    t18 = tote_items(:t18)
    assert t18.valid?
    get :new, tote_item_id: t18.id
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when not logged in" do
    get :new
    assert_response :redirect    
    assert_redirected_to login_path
  end

  test "should not get new when tote item id not in params" do
    log_in_as(@c1)
    get :new
    assert_response :redirect    
    assert_redirected_to postings_path    
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

  test "index should show info when user has subscription" do
    user = @c_subscription
    assert_equal 1, user.subscriptions.count
    log_in_as(user)
    get :index
    assert_response :success
    assert_template 'subscriptions/index'

    sd = assigns(:skip_dates)
    assert sd.count > 0
    assert assigns(:end_date) > user.subscriptions.last.posting_recurrence.reference_date    
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

  test "should not show subscription if incorrect user" do
    log_in_as(@c1)
    get :show, id: @subscription.id
    assert_response :redirect
    assert_redirected_to subscriptions_path
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
