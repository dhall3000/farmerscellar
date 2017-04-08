require 'integration_helper'
require 'utility/rake_helper'
require 'integration_helper'

class ToteItemsControllerTest < IntegrationHelper

  def setup
    @c1 = users(:c1)
    @posting_apples = postings(:postingf1apples)
  end

  test "posting important notes should display properly" do
    #we're going to test that the important_notes/important_notes_body do/don't show up at the right time

    log_in_as(@c1)

    #first verify that when there are no important notes, nothing is displayed
    @posting_apples.update(important_notes: nil, important_notes_body: nil)
    get posting_path(@posting_apples)
    assert_response :success
    assert_template 'postings/show'
    assert_select '#important-notes-info-glyph', {count: 0}
    assert_select '#important-notes-chevron-glyph', {count: 0}

    #next verify that when there are important notes they are displayed
    @posting_apples.update(important_notes: "important notes title", important_notes_body: nil)
    get posting_path(@posting_apples)
    assert_response :success
    assert_template 'postings/show'
    assert_select '#important-notes-info-glyph', {count: 1}
    assert_select '#important-notes-chevron-glyph', {count: 0}
    assert_match @posting_apples.important_notes, response.body

    #now verify that when there are important notes_body they also are displayed
    @posting_apples.update(important_notes: "important notes title", important_notes_body: "important notes body")
    get posting_path(@posting_apples)
    assert_response :success
    assert_template 'postings/show'
    assert_select '#important-notes-info-glyph', {count: 1}    
    assert_match @posting_apples.important_notes, response.body
    assert_match @posting_apples.important_notes_body, response.body

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
    post tote_items_path, params: {quantity: 1, posting_id: @posting_apples.id}
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
    get posting_path(@posting_apples)
    assert_response :redirect
    assert_redirected_to postings_path

    assert_not flash.empty?
    assert_equal "Oops, that posting is no longer active", flash[:danger]    
  end

  test "should get new for live posting if attempt made to pull up old unlive posting from an active posting recurrence" do
    nuke_all_postings

    #create posting recurrence
    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = get_delivery_date(days_from_now = 3), order_cutoff = get_delivery_date(days_from_now = 1), units_per_case = nil, frequency = 1).posting_recurrence
    #skip ahead to the order cutoff of the first posting and trigger it to generate the 2nd posting. this will put
    #the first posting in a CLOSED state
    travel_to pr.current_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 2, pr.postings.count
    
    #check that the 2 postings are in the proper states
    assert pr.reload.postings.first.state?(:CLOSED)
    closed_posting = pr.postings.first
    closed_posting_id = pr.postings.first.id

    assert pr.postings.last.state?(:OPEN)
    opened_posting = pr.postings.last
    opened_posting_id = pr.postings.last.id

    assert opened_posting_id != closed_posting_id

    #now log in and verify that the 2nd (i.e. OPENed) posting can be accessed
    log_in_as(@c1)    
    get posting_path(opened_posting)
    assert_response :success
    assert_template 'postings/show'
    posting = assigns(:posting)
    assert posting.valid?
    assert posting.state?(:OPEN)
    assert_equal opened_posting_id, posting.id

    #and now verify that if an attempt is made to view the 1st (i.e. CLOSEd) posting it will redirect to display the 2nd OPEN posting
    get posting_path(closed_posting)
    assert_response :redirect
    assert_redirected_to posting_path(opened_posting)
    follow_redirect!
    assert_response :success
    assert_template 'postings/show'
    posting = assigns(:posting)
    assert posting.valid?
    assert posting.state?(:OPEN)
    assert_equal opened_posting_id, posting.id

    travel_back
  end

  test "should auto assign dropsite if only one dropsite exists and user has not specified a dropsite" do        
    #verify only one dropsite exists
    dropsite = dropsites(:dropsite2)
    nuke_dropsite(dropsite)
    dropsite = dropsites(:dropsite3)
    nuke_dropsite(dropsite)
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
    next
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
    items_total_gross = assigns(:items_total_gross)
    assert items_total_gross > 0

  end

  test "should get billing agreement on index" do
    log_in_as(@c1)
    get tote_items_path
    assert_response :success
    assert_template 'tote_items/tote'
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
    assert_template 'tote_items/tote'
    rtba = assigns(:rtba)
    assert rtba.nil?    
  end

  test "should display helpful text on index" do    
    #if user has no tote items helpful text should be rendered
    log_in_as(users(:c_no_tote_items))
    get tote_items_path
    assert_response :success
    assert_template 'tote_items/tote'
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
    post tote_items_path, params: {quantity: 1, posting_id: @posting_apples.id}

    assert_equal "Tote item added", flash[:success]
    assert :redirected
    assert_response :redirect
    assert_redirected_to postings_path

  end
    
  test "should not create tote item when posting is not live" do

    @posting_apples.update(live: false)

    log_in_as(@c1)
    post tote_items_path, params: {quantity: 1, posting_id: @posting_apples.id}

    assert_equal "Oops, please try adding that again", flash[:danger]
    assert_redirected_to postings_path
    
  end

  test "should not get create" do

    log_in_as(@c1)

    #zero quantity should fail
    post tote_items_path, params: {quantity: 0, posting_id: @posting_apples.id}

    assert_equal "Invalid quantity", flash.now[:danger]
    assert_response :redirect
    assert_redirected_to posting_path(@posting_apples)
    follow_redirect!
    assert_template 'postings/show'

  end

  test "should render how often page" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    subscription_count = Subscription.where(user_id: @c1.id).count

    post tote_items_path, params: {quantity: 2, posting_id: postings(:p_recurrence_on).id }

    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly zero additional tote item in the database after the post operation
    assert_equal ti_count , c1_tote_items.count
    
    assert_response :success
    assert_template "tote_items/how_often"

  end
  
  test "should not redirect to new subscription when posting recurrence is off" do

    log_in_as(@c1)    
    subscription_frequency = 1
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    ti_count = c1_tote_items.count
    posting = postings(:p_recurrence_off)
    post tote_items_path, params: {quantity: 2, posting_id: postings(:p_recurrence_off).id }
    
    c1_tote_items = ToteItem.where(user_id: @c1.id)
    #verify there's exactly one additional tote item in the database after the post operation
    assert_equal ti_count + 1, c1_tote_items.count
    new_ti = c1_tote_items.last
    
    assert_equal "Tote item added", flash[:success]
    assert_redirected_to postings_path

  end

  test "should do hold behavior on create" do

    log_in_as(users(:c_account_on_hold))
    post tote_items_path, params: {posting_id: Posting.last.id, quantity: 1}

    assert :redirected
    assert_equal "Your account is on hold. Please contact Farmer's Cellar.", flash[:danger]
    assert_not assigns(:tote_item)
    assert_not assigns(:subscription)  

  end

end