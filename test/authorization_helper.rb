require 'test_helper'

class Authorizer < ActionDispatch::IntegrationTest

  def setup
    @c1 = users(:c1)
    @c2 = users(:c2)
    @c3 = users(:c3)
    @c4 = users(:c4)
    @c_no_tote_items = users(:c_no_tote_items)
    @c_one_tote_item = users(:c_one_tote_item)
    @dropsite1 = dropsites(:dropsite1)
    @dropsite2 = dropsites(:dropsite2)
    puts "AuthorizationsTest output:-----------------------------"
  end

  def create_authorization_for_customers(customers)

    num_added_tote_items_before = ToteItem.where(state: ToteItem.states[:ADDED]).count
    num_authorized_tote_items_before = ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count

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
    num_added_tote_items_after = ToteItem.where(state: ToteItem.states[:ADDED]).count
    num_authorized_tote_items_after = ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count

    assert num_added_tote_items_after < num_added_tote_items_before
    assert num_authorized_tote_items_after > num_authorized_tote_items_before

  end

  def create_authorization_for_customer(customer)
    log_in_as(customer)

    get dropsites_path
    assert_template 'dropsites/index'
    get dropsite_path(@dropsite1)
    assert_template 'dropsites/show'
    post user_dropsites_path, user_dropsite: {user_id: customer.id, dropsite_id: @dropsite1.id}

    get tote_items_path
    assert_response :success
    assert_template 'tote_items/index'
    assert_not_nil assigns(:tote_items)
    total_amount_to_authorize = assigns(:total_amount_to_authorize)
    assert_not_nil total_amount_to_authorize
    assert total_amount_to_authorize > 0, "total amount of tote items is not greater than zero"
    puts "total_amount_to_authorize = $#{total_amount_to_authorize}"
    post checkouts_path, amount: total_amount_to_authorize, use_reference_transaction: "0"
    checkout_tote_items = assigns(:checkout_tote_items)
    assert_not_nil checkout_tote_items
    assert checkout_tote_items.any?
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
    num_mail_messages_sent = ActionMailer::Base.deliveries.size
    post authorizations_path, authorization: {token: authorization.token, payer_id: authorization.payer_id, amount: authorization.amount}    
    authorization = assigns(:authorization)
    verify_authorization_receipt_sent(num_mail_messages_sent, customer, authorization)
    assert_not_nil authorization
    assert_not_nil authorization.transaction_id
    assert_template 'authorizations/create'
    return authorization
  end

  def verify_authorization_receipt_sent(num_mail_messages_sent, user, authorization)

    #did a mail message even go out?
    assert_equal ActionMailer::Base.deliveries.size, num_mail_messages_sent + 1

    mail = ActionMailer::Base.deliveries.last
    assert_equal [user.email], mail.to
    assert_match "Authorization receipt", mail.subject    
    assert_match "payment authorization receipt for", mail.body.encoded
    
    assert_match authorization.checkouts.last.tote_items.last.posting.user.farm_name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.product.name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.price.to_s, mail.body.encoded
    assert authorization.checkouts.last.tote_items.last.price > 0
    assert authorization.checkouts.last.tote_items.last.quantity > 0
    assert_match authorization.checkouts.last.tote_items.last.quantity.to_s, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.unit_kind.name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.delivery_date.strftime("%A %b %d, %Y"), mail.body.encoded

    assert authorization.amount > 0
    assert_match authorization.amount.to_s, mail.body.encoded

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
    post checkouts_path, amount: total_amount, use_reference_transaction: "0"
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