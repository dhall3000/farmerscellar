require 'test_helper'

class ToteItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @c1 = users(:c1)
    @posting_apples = postings(:postingf1apples)
  end

  test "tote item helper methods should return correct values" do
    tote_items = ToteItemsController.helpers.unauthorized_items_for(@c1)
    assert_equal 11, tote_items.count

    tote_items = ToteItemsController.helpers.authorized_items_for(@c1)
    assert_equal 0, tote_items.count

    subscriptions = ToteItemsController.helpers.get_active_subscriptions_by_authorization_state(users(:c_subscription))
    assert_equal 1, subscriptions[:unauthorized].count
    assert_equal 0, subscriptions[:authorized].count
  end

  test "should not create tote item for unlive posting" do
    @posting_apples.update(live: false)
    @posting_apples.reload
    assert_not @posting_apples.live

    log_in_as(@c1)

    tote_items_count = @c1.tote_items.count
    post tote_items_path, params: {tote_item: {quantity: 1, posting_id: @posting_apples.id}}
    @c1.reload
    assert_equal tote_items_count, @c1.tote_items.count
    assert_response :redirect
    assert_redirected_to postings_path

    assert_not flash.empty?
    assert_equal "Oops, please try adding that again", flash[:danger]    
  end

  test "should not get new for unlive posting" do
    @posting_apples.update(live: false)
    @posting_apples.reload
    assert_not @posting_apples.live

    log_in_as(@c1)
    get new_tote_item_path(posting_id: @posting_apples.id)
    assert_response :redirect
    assert_redirected_to postings_path

    assert_not flash.empty?
    assert_equal "Oops, please try adding that again", flash[:danger]    
  end

  test "should auto assign dropsite if only one dropsite exists and user has not specified a dropsite" do    
    #verify only one dropsite exists
    dropsite = dropsites(:dropsite2)
    dropsite.destroy
    dropsite = dropsites(:dropsite3)
    dropsite.destroy
    assert_equal 1, Dropsite.count
    #verify user does not have dropsite specified
    c5 = users(:c5)
    log_in_as(c5)
    assert_not c5.dropsite
    #verify user does not have pickup code
    assert_not c5.pickup_code
    #view index
    get tote_items_path
    assert :success
    #verify user now has dropsite
    assert c5.dropsite
    assert c5.dropsite.valid?
    #verify user now has pickup code
    c5.reload    
    assert c5.pickup_code
    assert c5.pickup_code.valid?
    assert_not c5.pickup_code.code.nil?
  end

  test "should prompt user to select dropsite" do
    #verify more than one dropsite
    assert Dropsite.count > 1
    #verify no dropsite specified
    c5 = users(:c5)
    log_in_as(c5)
    assert_not c5.dropsite
    #view index
    get tote_items_path
    assert :success
    #verify user still has no dropsite specified
    c5.reload
    assert_not c5.dropsite
    #verify warning messages appear
    assert_select 'p.alert.alert-danger', "No delivery dropsite specified."    
    #verify checkout button disabled
    assert_select '#paypal-button[disabled=?]', "disabled"
  end

  test "should get index" do

    log_in_as(@c1)
    get tote_items_path
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
    get tote_items_path
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
    get tote_items_path
    assert_response :success
    assert_template 'tote_items/index'
    rtba = assigns(:rtba)
    assert rtba.nil?    
  end

  test "should display helpful text on index" do    
    #if user has no tote items helpful text should be rendered
    log_in_as(users(:c_no_tote_items))
    get tote_items_path
    assert_response :success
    assert_template 'tote_items/index'
    assert_match 'p', "Your shopping tote is empty so there is nothing to view here."
  end

  test "should display help text when not logged in for index" do
    get tote_items_path
    assert_response :redirect
    assert_redirected_to login_path
    assert_not flash.empty?
    assert_equal "Please log in or sign up.", flash[:danger]    
  end

  test "should get create" do

    log_in_as(@c1)
    post tote_items_path, params: {tote_item: {quantity: 1, posting_id: @posting_apples.id}}

    assert_equal "Item added to tote.", flash[:success]
    assert :redirected
    assert_response :redirect
    assert_redirected_to postings_path

  end
    
  test "should not create tote item when posting is not live" do

    @posting_apples.update(live: false)

    log_in_as(@c1)
    post tote_items_path, params: {tote_item: {quantity: 1, posting_id: @posting_apples.id}}

    assert_equal "Oops, please try adding that again", flash[:danger]
    assert_redirected_to postings_path
    
  end

  test "should not get create" do

    log_in_as(@c1)

    #zero quantity should fail
    post tote_items_path, params: {tote_item: {quantity: 0, posting_id: @posting_apples.id}}

    assert_equal "Item not added to tote. See errors below.", flash.now[:danger]
    assert_template 'tote_items/new'

  end

  test "should redirect to subscription new" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    subscription_count = Subscription.where(user_id: @c1.id).count

    post tote_items_path, params: {tote_item: {quantity: 2, posting_id: postings(:p_recurrence_on).id }}

    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly one additional tote item in the database after the post operation
    assert_equal ti_count + 1 , c1_tote_items.count
    new_ti = c1_tote_items.last
    assert_equal ToteItem.states[:ADDED], new_ti.state
    
    assert_response :redirect
    assert_redirected_to new_subscription_path(tote_item_id: new_ti.id)

  end
  
  test "should not redirect to new subscription when posting recurrence is off" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    posting = postings(:p_recurrence_off)
    post tote_items_path, params: {tote_item: {quantity: 2, posting_id: postings(:p_recurrence_off).id }}
    
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly one additional tote item in the database after the post operation
    assert_equal ti_count + 1, c1_tote_items.count
    new_ti = c1_tote_items.last
    
    assert_equal "Item added to tote.", flash[:success]
    assert_redirected_to postings_path

  end

  test "should do hold behavior on create" do

    log_in_as(users(:c_account_on_hold))
    post tote_items_path #TODO: COME BACK HERE AND PUT LEGIT PARAMETERS HERE

    assert :redirected
    assert_equal flash[:danger], "Your account is on hold. Please contact Farmer's Cellar."
    assert_not assigns(:tote_item)
    assert_not assigns(:subscription)  

  end

end