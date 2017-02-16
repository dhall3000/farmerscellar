require 'test_helper'

class EmailTest < ActiveSupport::TestCase

  test "email should have subject" do
    email = Email.new(body: "hello body")
    assert_not email.valid?    
  end

  test "email should have body" do
    email = Email.new(subject: "hello subject")
    assert_not email.valid?    
  end

  test "email should have posting" do
    email = Email.new(subject: "hello subject", body: "hello body")
    assert_not email.valid?    
  end

  test "email should be valid" do
    email = Email.new(subject: "hello subject", body: "hello body")
    posting = create_posting
    email.postings << posting
    assert email.valid?    
    assert email.save
  end

  test "should make proper to list" do
    
    #make two postings by same producer
    producer = create_producer
    posting1 = create_posting(producer, price = 10)
    posting2 = create_posting(producer, price = 20)
    #make three customers
    c1 = create_user("c1", email = "customer1@c.com")
    c2 = create_user("c2", email = "customer2@c.com")
    c3 = create_user("c3", email = "customer3@c.com")
    #customer 1 is of only one posting
    create_tote_item(c1, posting1, 1)
    create_one_time_authorization_for_customer(c1)
    #customer 2 is of only the other posting
    create_tote_item(c2, posting2, 1)
    create_one_time_authorization_for_customer(c2)
    #customer 3 is of both postings
    create_tote_item(c3, posting1, 1)
    create_tote_item(c3, posting2, 1)
    create_one_time_authorization_for_customer(c3)

    email = Email.new(subject: "mysubject", body: "mybody")
    email.postings << posting1
    email.postings << posting2

    assert email.valid?
    assert email.save
    assert_not email.send_time
    email.send_email
    assert email.send_time

    to_list = email.recipients

    assert_equal 3, to_list.count
    assert_equal 1, to_list.where(email: c1.email).count
    assert_equal 1, to_list.where(email: c2.email).count
    assert_equal 1, to_list.where(email: c3.email).count

  end

  test "should make proper to list when producers wants to mail not all his postings" do
    
    #make 3 postings by same producer
    producer = create_producer
    posting1 = create_posting(producer, price = 10)
    posting2 = create_posting(producer, price = 20)
    posting3 = create_posting(producer, price = 20)
    #make five customers
    c1 = create_user("c1", email = "customer1@c.com")
    c2 = create_user("c2", email = "customer2@c.com")
    c3 = create_user("c3", email = "customer3@c.com")
    c4 = create_user("c4", email = "customer4@c.com")
    c5 = create_user("c5", email = "customer5@c.com")
    #customer 1 is of only one posting
    create_tote_item(c1, posting1, 1)
    create_one_time_authorization_for_customer(c1)
    #customer 2 is of only the other posting
    create_tote_item(c2, posting2, 1)
    create_one_time_authorization_for_customer(c2)
    #customer 3 is of both postings
    create_tote_item(c3, posting1, 1)
    create_tote_item(c3, posting2, 1)
    create_one_time_authorization_for_customer(c3)
    #customer 4 is only of posting 3
    create_tote_item(c4, posting3, 1)
    create_one_time_authorization_for_customer(c4)

    email = Email.new(subject: "mysubject", body: "mybody")
    email.postings << posting1
    email.postings << posting2

    assert email.valid?
    assert email.save
    assert_not email.send_time
    email.send_email
    assert email.send_time

    to_list = email.recipients

    assert_equal 3, to_list.count
    assert_equal 1, to_list.where(email: c1.email).count
    assert_equal 1, to_list.where(email: c2.email).count
    assert_equal 1, to_list.where(email: c3.email).count
    assert_equal 0, to_list.where(email: c4.email).count

    assert_equal 1, posting1.emails.count
    assert_equal 1, posting2.emails.count
    assert_equal 0, posting3.emails.count    

  end

end