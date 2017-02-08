require 'integration_helper'

class EmailsControllerTest < IntegrationHelper

  test "should not get index if user not logged in" do
    get emails_path
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should not get new if user not logged in" do
    get new_email_path
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should not get new if logged in user is not a producer" do        
    log_in_as(users(:c1))
    get new_email_path
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should not get new if there are no postings to send a message to" do
    producer = create_producer
    get_access_for(producer)
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'
    get new_email_path
    assert_response :redirect
    assert_redirected_to producer
    assert_not flash.empty?
    assert_equal "There are no postings to send a message to", flash[:danger]
  end

  test "should get new when conditions warrant" do
    #must have at least one eligible posting to send email to
    producer = create_producer
    get_access_for(producer)
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path
    create_posting(producer)
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'
    get new_email_path
    assert_response :success
    assert_template 'emails/new'
  end

  test "should not get show if user not logged in" do        
    email = create_email
    log_out    
    get email_path(email)
    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should not get show if incorrect user" do
    email = create_email
    producer = create_producer("producer bob", "bob@b.com")
    log_in_as(producer)
    assert_not_equal email.postings.first.user.id, producer.id
    get email_path(email)
    assert_response :redirect
    assert_redirected_to root_path
    assert_not flash.empty?
    assert_equal "You do not have access to view this email", flash[:danger]
  end

  test "should get show as conditions warrant" do        
    email = create_email
    producer = email.postings.first.user
    log_in_as(producer)    
    get email_path(email)
    assert_response :success
    assert_template 'emails/show'
    assert flash.empty?    
  end

  test "should not create email without a subject" do
    producer = create_producer
    get_access_for(producer)
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path
    posting = create_posting(producer)
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'
    get new_email_path
    assert_response :success
    assert_template 'emails/new'

    post emails_path, params: {email: {body: "mybody"}, posting_ids: [posting.id]}
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "Email failed to send", flash.now[:danger]

  end

  test "should not create email without a body" do
    producer = create_producer
    get_access_for(producer)
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path
    posting = create_posting(producer)
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'
    get new_email_path
    assert_response :success
    assert_template 'emails/new'

    post emails_path, params: {email: {subject: "mysubject"}, posting_ids: [posting.id]}
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "Email failed to send", flash.now[:danger]
  end

  test "should not create email without at least one posting" do
    producer = create_producer
    get_access_for(producer)
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path    
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'

    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}}
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "You must specify at least one posting to send email to", flash[:danger]
    assert_response :redirect
    assert_redirected_to producer
  end

  test "should not create email if any postings do not belong to producer" do

    producer1 = create_producer(name = "producer1", email = "producer1@p.com", distributor = nil, order_min = 0)
    get_access_for(producer1)
    log_in_as(producer1)
    assert_response :redirect
    assert_redirected_to root_path
    posting = create_posting(producer1)

    producer2 = create_producer(name = "producer2", email = "producer2@p.com", distributor = nil, order_min = 0)
    get_access_for(producer2)

    log_in_as(producer2)
    assert_response :redirect
    assert_redirected_to root_path    
    log_in_as(producer2)
    get user_path(producer2)
    assert_response :success
    assert_template 'users/show'

    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [posting.id]}
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "You can't send email to at least one of these postings", flash[:danger]
    assert_response :redirect
    assert_redirected_to producer2
  end

  test "should create and send email as conditions warrant" do

    producer = create_producer
    get_access_for(producer)    
    log_in_as(producer)
    assert_response :redirect
    assert_redirected_to root_path    
    posting = create_posting(producer)
    bob = create_new_customer("bob", "bob@b.com")
    ti = create_tote_item(bob, posting, quantity = 1)
    assert ti.valid?
    ti.update(state: ToteItem.states[:AUTHORIZED])
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [posting.id]}
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = assigns(:email)
    assert email.valid?
    assert_not flash.empty?
    assert_equal "Email successfully sent", flash[:success]
    assert_response :redirect
    assert_redirected_to emails_path

  end

end
