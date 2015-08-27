require 'test_helper'

class PostingsControllerTest < ActionController::TestCase

  def setup
  	@user = users(:f1)
  	@posting = postings(:postingf1apples)
  end

  test "gracefully fail to create posting if price not set" do
    #log in
    log_in_as(@user)
    #make a posting that doesn't have price set
    post :create, id: @user.id, posting: { description: "descrip", quantity_available: 10, live: true, delivery_date: "3000-08-28" }
    #verify redirection    
    assert_template 'postings/new'
    #verify sad message
    posting = assigns(:posting)    
    assert_not posting.valid?
    #this is for the flash
    assert_select 'div.alert-danger', "The form contains 2 errors."    

    #this is for the specific errors that should be reported to the user
    assert_select 'div#error_explanation' do
      assert_select 'ul' do
        assert_select 'li', "Price can't be blank"
        assert_select 'li', "Price is not a number"
      end
    end

  end

  test "newly created posting is posted when created properly with live set" do
    log_in_as(@user)
    get :index
    postings = assigns(:postings)
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"
    postings_count_prior = postings.count
    successfully_create_posting
    posting = assigns(:posting)
    assert_not posting.nil?
    get :index
    postings = assigns(:postings)
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"
    postings_count_post = postings.count
    assert postings_count_post > postings_count_prior, "the number of posts after successful post-creation was not greater than before successful post-creation"
  end

  #this new posting SHOULD show up in the My Postings section of the farmer's profile  
  test "newly created posting is not posted when created properly with live unset" do
    #this new posting should NOT show up in the shopping pages
    
    log_in_as(@user)
    get :index
    postings = assigns(:postings)        
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"
    postings_count_prior = postings.count
    
    successfully_create_posting_with_live_unset

    posting = assigns(:posting)
    assert_not posting.nil?
    get :index
    postings = assigns(:postings)
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"
    postings_count_post = postings.count
    assert postings_count_post == postings_count_prior, "the number of posts after successful non-live post-creation was not equal to the before successful non-live post-creation"
    
  end

  test "posted posting becomes unposted after unsetting live" do

  end

  test "unposted posting becomes posted after setting live" do

  end

  test "successfully create a posting" do
    successfully_create_posting
  end

  def successfully_create_posting
    #log in
    log_in_as(@user)
    #go to post creation page
    #specify values, submit form
    post :create, id: @user.id, posting: { description: "descrip", price: 1, quantity_available: 10, live: true, delivery_date: "3000-08-28", product_id: @posting.product_id, unit_kind_id: @posting.unit_kind.id, unit_category_id: @posting.unit_category.id }
    posting = assigns(:posting)
    assert_not posting.nil?
    assert posting.valid?
    assert_redirected_to postings_path
    assert_not flash.empty?
  end

  def successfully_create_posting_with_live_unset
    #log in
    log_in_as(@user)
    #go to post creation page
    #specify values, submit form
    post :create, id: @user.id, posting: { description: "descrip", price: 1, quantity_available: 10, live: false, delivery_date: "3000-08-28", product_id: @posting.product_id, unit_kind_id: @posting.unit_kind.id, unit_category_id: @posting.unit_category.id }
    posting = assigns(:posting)
    assert_not posting.nil?
    assert posting.valid?
    assert_redirected_to postings_path
    assert_not flash.empty?
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
    get :edit, id: @user
    assert_not flash.empty?
    assert_redirected_to login_url
  end

end
