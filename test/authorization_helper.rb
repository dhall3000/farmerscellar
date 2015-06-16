require 'test_helper'

class Authorizer < ActionDispatch::IntegrationTest

  def setup
    @c1 = users(:c1)
    @c2 = users(:c2)
    @c3 = users(:c3)
    @c4 = users(:c4)
    @c_no_tote_items = users(:c_no_tote_items)
    puts "AuthorizationsTest output:-----------------------------"
  end

  def create_authorization_for_customers(customers)

    for customer in customers

      #create a new auth
      newauthorization = create_authorization_for_customer(customer)
      #verify a new auth was actually created
      assert_not_nil newauthorization
      #attempt to pull this new auth from the db
      authorizationdb = Authorization.find_by(token: newauthorization.token)
      #verify the attempt to pull new auth from db succeeded
      assert_not_nil authorizationdb
      #verify the auth token in the db matches the auth token in memory
      assert_equal newauthorization.token, authorizationdb.token
    end    

    #check that as a result of the above authorizations at least some of the tote item states were changed from ADDED -> AUTHORIZED
    assert_equal 1, ToteItem.first.status

  end

  def create_authorization_for_customer(customer)
    log_in_as(customer)
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

end

module AuthorizationHelper

  def AuthorizationHelper.create_authorization_for_logged_in_user(user)
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

end