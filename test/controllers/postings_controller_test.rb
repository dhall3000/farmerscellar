require 'test_helper'

class PostingsControllerTest < ActionController::TestCase

  def setup
  	@farmer = users(:f1)
    @customer = users(:c1)
    @admin = users(:a1)
  	@posting = postings(:postingf1apples)
  end

  def get_new_successfully
    get :new
    assert_response :success
    assert_template 'postings/new'    
  end

  test "should get new for farmer and admin" do
    log_in_as(@farmer)
    get_new_successfully

    log_in_as(@admin)
    get_new_successfully    
  end

  test "should redirect on new for customer or non user" do
    #first try doing 'new' w/o logging in
    get :new
    assert_response :redirect
    assert_redirected_to login_url

    #now try logging in as customer. still should fail.
    log_in_as(@customer)
    get :new
    assert_response :redirect
    assert_redirected_to root_url
  end

  test "should copy posting on new" do
    log_in_as(@farmer)
    get :new, posting_id: @posting.id
    assert_response :success
    assert_template 'postings/new'

    #there should be a new posting form that's prepopulated with the old posting's values
    #do a spot check of one of the input fields to see if this is true
    assert_select '#posting_quantity_available' do
      assert_select "[value=?]", @posting.quantity_available.to_s
    end

  end

  def successfully_get_index
    get :index
    assert :success
    assert_template 'postings/index'

    #assert that there are at least several postings (this should be the case as long as there
    #are "at least several" postings in the posting.yml file)
    assert_select 'tbody' do |elements|
      elements.each do |element|
        assert_select 'tr', minimum: 3
      end
    end
  end

  test "should get index for users" do
    log_in_as(@customer)
    successfully_get_index

    log_in_as(@farmer)
    successfully_get_index
  end

  test "should get index for admin" do
    log_in_as(@admin)
    successfully_get_index

    #additionally, the admin postings index page should have a table with 'Edit' and 'Go!' columns
    assert_select 'tbody' do
      assert_select 'a[href=?]', edit_posting_path(@posting), {count: 1, text: "Edit"}
      assert_select 'a[href=?]', tote_items_next_path( tote_item: {posting_id: @posting.id}), {count: 1, text: "Go!"}
    end

  end

  test "should not get index for non users" do
    get :index
    assert :redirect
    assert_redirected_to login_url
  end

  test "gracefully fail to create posting if price not set" do
    #log in
    log_in_as(@farmer)
    #make a posting that doesn't have price set
    posting_params = get_posting_params_hash
    posting_params.delete(:price)
    fail_to_create(posting_params)

    #now let's try it again but with a positive recurrence set. should fail gracefully.
    posting_params[:posting_recurrence] = {interval: PostingRecurrence.intervals[1][1], on: true}
    fail_to_create(posting_params)

  end

  def fail_to_create(posting_params)
    post :create, id: @farmer.id, posting: posting_params

    #verify redirection    
    assert_template 'postings/new'
    #verify sad message
    posting = assigns(:posting)    
    assert_not posting.valid?, get_error_messages(posting)    
    #this is for the flash

    assert_select 'div.alert-danger', "The form contains 1 error."

    #this is for the specific errors that should be reported to the user
    assert_select 'div#error_explanation' do
      assert_select 'ul' do
        assert_select 'li', "Price must be greater than 0"        
      end
    end
  end

  test "newly created posting is posted when created properly with live set" do
 
    postings_count_prior = get_postings_count
    successfully_create_posting
    posting = assigns(:posting)
    assert_not posting.nil?    
    postings_count_post = get_postings_count
    assert postings_count_post > postings_count_prior, "the number of posts after successful post-creation was not greater than before successful post-creation"

  end

  #this new posting SHOULD show up in the My Postings section of the farmer's profile  
  test "newly created posting is not posted when created properly with live unset" do
    #this new posting should NOT show up in the shopping pages
    
    postings_count_prior = get_postings_count

    successfully_create_posting_with_live_unset
    posting = assigns(:posting)
    assert_not posting.nil?
    
    postings_count_post = get_postings_count
    assert postings_count_post == postings_count_prior, "the number of posts after successful non-live post-creation was not equal to the before successful non-live post-creation"
    
  end

  #bundle exec rake test test/controllers/postings_controller_test.rb test_posted_posting_becomes_unposted_after_unsetting_live
  test "posted posting becomes unposted after unsetting live" do
    posting = successfully_create_posting
    postings_count_prior = get_postings_count
    live_prior = posting.live
    posting.live = false
    posting.save
    posting.reload
    live_post = posting.live
    assert live_prior != live_post
    postings_count_post = get_postings_count
    assert postings_count_post < postings_count_prior
  end

  test "unposted posting becomes posted after setting live" do
    posting = successfully_create_posting_with_live_unset
    postings_count_prior = get_postings_count
    live_prior = posting.live
    posting.live = true
    posting.save
    posting.reload
    live_post = posting.live
    assert live_prior != live_post
    postings_count_post = get_postings_count
    assert postings_count_post > postings_count_prior
  end

  test "successfully create a posting" do
    successfully_create_posting
  end

  def get_postings_count
    
    log_in_as(@farmer)
    get :index
    postings = assigns(:postings)        
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"

    return postings.count

  end

  def get_posting_params_hash

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    posting = {
      user_id: @farmer.id,
      description: "descrip",
      price: 1,
      quantity_available: 10,
      live: true,
      delivery_date: delivery_date,
      product_id: @posting.product_id,
      unit_kind_id: @posting.unit_kind.id,
      unit_category_id: @posting.unit_category.id,
      commitment_zone_start: delivery_date - 2.days
    }

    return posting

  end

  test "successfully create posting with recurrence set to not repeat" do
    successfully_create_posting_with_recurrence_set_to_not_repeat
  end

  def successfully_create_posting_with_recurrence_set_to_not_repeat
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    parms = get_posting_params_hash
    parms[:posting_recurrence] = {interval: PostingRecurrence.intervals[0][1], on: false}
    post :create, id: @farmer.id, posting: parms
    posting = assigns(:posting)        
    assert_not posting.nil?
    #the params were sent up to teh #create action with recurrence set to not repeat so we want to verify that .posting_recurrence is nil
    #because we don't want to create a db object for postings that don't repeat
    assert_not posting.posting_recurrence
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?    

    return posting    

  end

  test "successfully create posting with recurrence" do
    successfully_create_posting_with_recurrence
  end

  def successfully_create_posting_with_recurrence
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    posting_recurrence_count = PostingRecurrence.count

    parms = get_posting_params_hash
    parms[:posting_recurrence] = {interval: PostingRecurrence.intervals[1][1], on: true}
    post :create, id: @farmer.id, posting: parms
    posting = assigns(:posting)        
    assert_not posting.nil?    
    assert posting.posting_recurrence.valid?
    assert posting.valid?, get_error_messages(posting)
    #there should be more posting recurrences in the database now than thre was before this posting
    assert PostingRecurrence.count > posting_recurrence_count
    assert_redirected_to postings_path
    assert_not flash.empty?    

    return posting        
  end

  def successfully_create_posting
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    post :create, id: @farmer.id, posting: get_posting_params_hash
    posting = assigns(:posting)        
    assert_not posting.nil?
    #the params were sent up to teh #create action with no recurrence set so we want to verify that .posting_recurrence is nil
    #because we don't want to create a db object for postings that don't repeat
    assert_not posting.posting_recurrence
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?

    return posting

  end

  def successfully_create_posting_with_live_unset
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    posting_hash = get_posting_params_hash
    posting_hash[:live] = false

    post :create, id: @farmer.id, posting: posting_hash
      
    posting = assigns(:posting)
    assert_not posting.nil?
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?
    return posting
  end

  test "should get redirected if not logged in" do  	
    get :edit, id: @posting
    assert_not flash.empty?
    assert_redirected_to login_url    
  end

  test "should get new" do
  	return
    get :new
    assert_response :success
  end

  test "should redirect edit when not logged in" do
  	return
    get :edit, id: @farmer
    assert_not flash.empty?
    assert_redirected_to login_url
  end

end
