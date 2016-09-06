require 'test_helper'

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest

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
    post subscriptions_path, params: {tote_item_id: ti.id, frequency: 1}
    assert_response :redirect    
    assert_redirected_to subscriptions_path    
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
    post subscriptions_path, params: {tote_item_id: ti.id, frequency: 0}
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
    post subscriptions_path, params: {tote_item_id: ti.id, frequency: 1}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not create when posting does not recur" do
    log_in_as(@c1)
    c1apple = tote_items(:c1apple)
    assert c1apple.valid?
    post subscriptions_path, params: {tote_item_id: c1apple.id, frequency: 1}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not create when frequency not in recurrence options" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    post subscriptions_path, params: {tote_item_id: ti.id, frequency: 100}
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when frequency not in params" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    post subscriptions_path, params: {tote_item_id: ti.id}
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when user not logged in" do
    post subscriptions_path
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should not create when tote item id not in params" do
    log_in_as(@c1)
    post subscriptions_path
    assert_response :redirect
    assert_redirected_to postings_path
  end

  test "should not create when tote item id does not belong to current user" do
    log_in_as(@c1)
    t18 = tote_items(:t18)
    assert t18.valid?
    post subscriptions_path, params: {tote_item_id: t18.id}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should get new" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_on)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    get new_subscription_path, params: {tote_item_id: ti.id}
    assert_response :success
    assert_template 'subscriptions/new'
  end

  test "should not get new when posting recurrence is off" do
    log_in_as(@c1)
    posting = postings(:p_recurrence_off)
    ti = ToteItem.new(quantity: 1, price: posting.price, posting_id: posting.id, user_id: @c1.id)
    assert ti.valid?
    assert ti.save        
    get new_subscription_path, params: {tote_item_id: ti.id}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when posting does not recur" do
    log_in_as(@c1)
    c1apple = tote_items(:c1apple)
    assert c1apple.valid?
    get new_subscription_path, params: {tote_item_id: c1apple.id}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when tote item id does not belong to current user" do
    log_in_as(@c1)
    t18 = tote_items(:t18)
    assert t18.valid?
    get new_subscription_path, params: {tote_item_id: t18.id}
    assert_response :redirect    
    assert_redirected_to postings_path
  end

  test "should not get new when not logged in" do
    get new_subscription_path
    assert_response :redirect    
    assert_redirected_to login_path
  end

  test "should not get new when tote item id not in params" do
    log_in_as(@c1)
    get new_subscription_path
    assert_response :redirect    
    assert_redirected_to postings_path    
  end  

  test "should get index when user logged in" do
    log_in_as(@c1)
    get subscriptions_path
    assert_response :success
    assert_template 'subscriptions/index'
  end

  test "should not get index when user not logged in" do    
    get subscriptions_path
    assert_response :redirect    
    assert_redirected_to login_path
  end

  test "index should tell user when they have no subscriptions" do
    assert_equal 0, @c1.subscriptions.count
    log_in_as(@c1)
    get subscriptions_path
    assert_response :success
    assert_template 'subscriptions/index'
    assert_select 'p', "You do not have any subscriptions."
    assert_equal false, assigns(:subscriptions).any?
    assert_equal nil, assigns(:end_date)
    assert_equal nil, assigns(:skip_dates)
  end

  test "index should show info when user has subscription" do
    user = @c_subscription
    assert_equal 1, user.subscriptions.count
    log_in_as(user)
    get subscriptions_path
    assert_response :success
    assert_template 'subscriptions/index'

    sd = assigns(:skip_dates)
    assert sd.count > 0
    assert assigns(:end_date) > user.subscriptions.last.posting_recurrence.current_posting.delivery_date
  end

  test "index should not show skip dates for subscriptions that are paused" do
    user = @c_subscription
    assert_equal 1, user.subscriptions.count

    #pause the subscription. after doing this, no skip dates should show up for this subscription in the index.
    subscription = user.subscriptions.last
    subscription.update(paused: true)
    subscription.reload
    assert subscription.paused

    log_in_as(user)
    get subscriptions_path
    assert_response :success
    assert_template 'subscriptions/index'

    #this user only had a single subscription. we paused it above. there should be zero skip dates displayed on index. skip dates
    #are displayed as checkbox inputs
    assert_select 'input[type=?]', "checkbox", 0

  end

  test "should not get show when user not logged in" do
    get subscription_path(@subscription)
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should get show when user logged in" do
    log_in_as(@c_subscription)
    get subscription_path(@subscription)
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
    get subscription_path(@subscription)
    assert_response :redirect
    assert_redirected_to subscriptions_path
  end

  test "should not get edit when user not logged in" do
    get edit_subscription_path(@subscription)
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should get edit when user logged in" do
    log_in_as(@c_subscription)
    get edit_subscription_path(@subscription)
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

  test "edit should only show subscription delivery dates and not posting recurrence delivery dates" do

    c_subscription_1 = users(:c_subscription_1)
    subscription = subscriptions(:two)
    log_in_as(c_subscription_1)
    get edit_subscription_path(id: subscription.id, end_date: subscription.posting_recurrence.postings.first.delivery_date + (20 * 7).days)
    skip_dates = assigns(:skip_dates)
    pr = subscription.posting_recurrence

    #there should be a 2 week gap between pr's first posting and the first skip date

    seconds_per_hour = 60 * 60
    num_seconds_per_week = 7 * 24 * seconds_per_hour

    pr_first_delivery_date = pr.postings.first.delivery_date
    first_subscription_skip_date = skip_dates[0][:date]

    gap = first_subscription_skip_date - pr_first_delivery_date
    spacing_should_be = 2 * num_seconds_per_week

    if pr_first_delivery_date.dst? != first_subscription_skip_date.dst?
      spacing_should_be += seconds_per_hour
    end

    assert_equal spacing_should_be, gap

    #there should be 2 week gaps between all skip_dates
    count = 1
    while count < skip_dates.count

      gap = skip_dates[count][:date] - skip_dates[count - 1][:date]
      spacing_should_be = 2 * num_seconds_per_week

      if !skip_dates[count][:date].dst? && skip_dates[count - 1][:date].dst?
        spacing_should_be += seconds_per_hour
      end

      if skip_dates[count][:date].dst? && !skip_dates[count - 1][:date].dst?
        spacing_should_be -= seconds_per_hour
      end        
      
      assert_equal spacing_should_be, gap
      count += 1
      
    end

  end

end
