require 'test_helper'

class ToteItemsControllerTest < ActionController::TestCase

  def setup
    @c1 = users(:c1)
    @posting_apples = postings(:postingf1apples)
  end

  test "should get index" do

    log_in_as(@c1)
    get :index
    assert_response :success
    dropsite = assigns(:dropsite)
    assert_not dropsite.nil?
    tote_items = assigns(:tote_items)
    assert_not tote_items.nil?
    assert tote_items.any?
    total_amount_to_authorize = assigns(:total_amount_to_authorize)
    assert total_amount_to_authorize > 0

  end

  test "should get billing agreement on index" do
    log_in_as(@c1)
    get :index
    assert_response :success
    assert_template 'tote_items/index'
    rtba = assigns(:rtba)
    assert_not rtba.nil?
    assert rtba.active
  end

  test "should not get billing agreement on index" do
    log_in_as(@c1)
    rtba = @c1.get_active_rtba
    rtba.update(active: false)
    get :index
    assert_response :success
    assert_template 'tote_items/index'
    rtba = assigns(:rtba)
    assert rtba.nil?    
  end

  test "should display helpful text on index" do    
    #if user has no tote items helpful text should be rendered
    log_in_as(users(:c_no_tote_items))
    get :index
    assert_response :success
    assert_template 'tote_items/index'
    assert_match 'p', "Your shopping tote is empty so there is nothing to view here."
  end

  test "should display help text when not logged in for index" do

    get :index
    assert_response :success
    assert_select 'p', "Sorry, you need to log in before you can view the contents of your tote"

    dropsite = assigns(:dropsite)
    assert dropsite.nil?
    tote_items = assigns(:tote_items)
    assert tote_items.nil?
    total_amount_to_authorize = assigns(:total_amount_to_authorize)
    assert total_amount_to_authorize.nil?

  end

  test "should get create" do

    log_in_as(@c1)
    post :create, tote_item: {quantity: 1, price: 2, status: ToteItem.states[:ADDED], posting_id: @posting_apples, user_id: @c1}

    assert_equal "Item saved to shopping tote.", flash[:success]
    assert :redirected
    assert_response :redirect
    assert_redirected_to postings_path

  end
    
  test "should not create subscription if quantity not positive" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    subscription_count = Subscription.where(user_id: @c1.id).count

    post :create, tote_item:
    {
      subscription_frequency: subscription_frequency,
      quantity: 0,
      price: 5.21,
      status: ToteItem.states[:ADDED],
      posting_id: postings(:p_recurrence_on),
      user_id: @c1
    }

    subscription = assigns(:subscription)
    assert_not subscription.nil?
    assert_not subscription.valid?
    assert_template 'tote_items/new'
    assert_equal "Subscription not saved. See errors below.", flash.now[:danger]

  end

  test "should not create tote item when posting is not live" do

    @posting_apples.update(live: false)

    log_in_as(@c1)
    post :create, tote_item: {quantity: 1, price: 2, status: ToteItem.states[:ADDED], posting_id: @posting_apples, user_id: @c1}

    assert_equal "Oops, it appears that posting is no longer live. Item not created.", flash[:danger]
    assert_redirected_to postings_path
    
  end

  test "should not get create" do

    log_in_as(@c1)

    #zero quantity should fail
    post :create, tote_item: {quantity: 0, price: 2, status: ToteItem.states[:ADDED], posting_id: @posting_apples, user_id: @c1}

    assert_equal "Item not saved to shopping tote. See errors below.", flash.now[:danger]
    assert_template 'tote_items/new'

  end

  test "should create subscription" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    subscription_count = Subscription.where(user_id: @c1.id).count

    post :create, tote_item:
      {
        subscription_frequency: subscription_frequency,
        quantity: 2,
        price: 5.21,
        status: ToteItem.states[:ADDED],
        posting_id: postings(:p_recurrence_on),
        user_id: @c1
      }

    subscription = assigns(:subscription)
    assert_not subscription.nil?
    assert subscription.valid?

    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly one additional tote item in the database after the post operation
    assert_equal ti_count + 1 , c1_tote_items.count
    new_ti = c1_tote_items.last
    #verify new tote item refers to the proper subscription
    assert_equal new_ti.subscription.id, subscription.id
    assert_equal ToteItem.states[:ADDED], new_ti.status
    #verify this user has exactly one more subscription object since the post operation
    assert_equal subscription_count + 1, Subscription.where(user_id: @c1.id).count
    assert_equal true, subscription.on
    assert_equal subscription_frequency, subscription.frequency

    assert_equal "New subscription created.", flash[:success]
    assert_redirected_to postings_path

  end

  test "should not create subscription when posting recurrence is off" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    subscription_count = Subscription.where(user_id: @c1.id).count

    post :create, tote_item:
      {
        subscription_frequency: subscription_frequency,
        quantity: 2,
        price: 5.21,
        status: ToteItem.states[:ADDED],
        posting_id: postings(:p_recurrence_off),
        user_id: @c1
      }

    subscription = assigns(:subscription)
    assert subscription.nil?
    
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly one additional tote item in the database after the post operation
    assert_equal ti_count, c1_tote_items.count
    new_ti = c1_tote_items.last
    
    #verify this user has exactly one more subscription object since the post operation
    assert_equal subscription_count, Subscription.where(user_id: @c1.id).count    

    assert_equal flash[:danger] = "Oops, it appears that posting is no longer live. Subscription not created.", flash[:danger]
    assert_redirected_to postings_path

  end

  test "should do hold behavior on create" do

    log_in_as(users(:c_account_on_hold))
    post :create #COME BACK HERE AND PUT LEGIT PARAMETERS HERE

    assert :redirected
    assert_equal flash[:danger], "Your account is on hold. Please contact Farmer's Cellar."
    assert_not assigns(:tote_item)
    assert_not assigns(:subscription)  

  end

  test "should get show" do
    #get :show
    #assert_response :success
  end

  test "should get new" do
    #get :new
    #assert_response :success
  end

  test "should get edit" do
    #get :edit
    #assert_response :success
  end

  test "should get destroy" do
    #get :destroy
    #assert_response :success
  end

end
