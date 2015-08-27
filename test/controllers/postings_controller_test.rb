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

  end

  test "successfully create a posting" do
    #log in
    log_in_as(@user)
    #go to post creation page
    #specify values, submit form
    post :create, id: @user.id, posting: { description: "descrip", price: 1, quantity_available: 10, live: true, delivery_date: "3000-08-28" }
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
