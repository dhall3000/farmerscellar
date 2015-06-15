require 'test_helper'

class AuthorizationsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  def setup
    @c1 = users(:c1)
    @c2 = users(:c2)
    @c3 = users(:c3)
    @c4 = users(:c4)
    @c_no_tote_items = users(:c_no_tote_items)
  end

  #this should create an auth in the db for each customer that has tote items
  test "should create new authorizations" do
    #log_in_as(@c_no_tote_items)    
    puts "number of authorizations: #{Authorization.count}"

    newauthorization = create_authorization_for_user(@c1)
    authorizationdb = Authorization.find_by(token: newauthorization.token)
    assert_not_nil authorizationdb
    puts "authorization token pulled from the db: #{authorizationdb.token}"
    assert_equal newauthorization.token, authorizationdb.token
    
    create_authorization_for_user(@c2)
    create_authorization_for_user(@c3)
    create_authorization_for_user(@c4)    
  end

  def create_authorization_for_user(user)
    log_in_as(user)
    get tote_items_path
    assert_response :success
    assert_template 'tote_items/index'
    assert_not_nil assigns(:tote_items)
    total_amount = assigns(:total_amount)
    assert_not_nil total_amount
    assert total_amount > 0, "total amount of tote items is not greater than zero"
    puts "total_amount = $#{total_amount}"
    post checkouts_path, amount: total_amount
    tote_items = assigns(:tote_items)
    assert_not_nil tote_items
    assert tote_items.any?
    checkout = assigns(:checkout)
    assert_not_nil checkout
    puts "checkout token: #{checkout.token}"
    puts "checkout amount: #{checkout.amount}"
    assert_redirected_to new_authorization_path(token: checkout.token)    
    follow_redirect!    
    authorization = assigns(:authorization)
    assert_not_nil authorization
    assert authorization.token = checkout.token, "authorization.token not equal to checkout.token"
    assert authorization.amount = checkout.amount, "authorization.amount not equal to checkout.token"
    assert_template 'authorizations/new'
    post authorizations_path, authorization: {token: authorization.token, payer_id: authorization.payer_id, amount: authorization.amount}
    authorization = assigns(:authorization)
    assert_not_nil authorization
    assert_not_nil authorization.transaction_id
    assert_template 'authorizations/create'
    return authorization
  end

  test "successful authorization" do
  	#log_in_as(@c1)
  	#get tote_items_path
  	#post checkouts_path, amount: total_cost_of_tote_items(current_user_current_tote_items)
  end
end