require 'integration_helper'

class ProducerAlertEmailsTest < IntegrationHelper

  def setup
    #make a producer
    @producer = create_producer
    get_access_for(@producer)
    #make two postings
    @posting1 = create_posting(@producer, price = 1, product = products(:apples))
    @posting2 = create_posting(@producer, price = 2, product = products(:celery))
    #make two customers
    @bob = create_new_customer("bob", "bob@b.com")
    @sam = create_new_customer("sam", "sam@s.com")
    #make ti for one customer for posting1
    @ti_bob = create_tote_item(@bob, @posting1, 1)
    #make ti for other customer for posting2
    @ti_sam = create_tote_item(@sam, @posting2, 1)

    log_in_as(@producer)
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "no email should be sent when no tote item states are checked" do

    #post excludes tote_item_states param entirely

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id]}
    assert_equal 0, ActionMailer::Base.deliveries.count
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "Invalid tote item states selected", flash[:danger]
    
    assert_response :redirect
    assert_redirected_to @producer

    #verify bob doesn't get an email
    #verify sam doesn't get an email
    #dont by the ActionMailer::Base.deliveries.count == 0 check above

  end

  test "no email should be sent when no tote item states are checked 2" do

    #post includes nil value for tote_item_states param

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id], tote_item_states: nil}
    assert_equal 0, ActionMailer::Base.deliveries.count
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "Invalid tote item states selected", flash[:danger]
    
    assert_response :redirect
    assert_redirected_to @producer

    #verify bob doesn't get an email
    #verify sam doesn't get an email
    #dont by the ActionMailer::Base.deliveries.count == 0 check above

  end

  test "no email should be sent when no tote item states are checked 3" do

    #post includes empty array (i.e. []) value for tote_item_states param

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id], tote_item_states: []}
    assert_equal 0, ActionMailer::Base.deliveries.count
    email = assigns(:email)
    assert_not email.valid?
    assert_not flash.empty?
    assert_equal "Invalid tote item states selected", flash[:danger]
    
    assert_response :redirect
    assert_redirected_to @producer

    #verify bob doesn't get an email
    #verify sam doesn't get an email
    #dont by the ActionMailer::Base.deliveries.count == 0 check above

  end

  test "no email should be sent when tote item state checked does not match bob tote item state" do
    @ti_bob.update(state: ToteItem.states[:AUTHORIZED])
    assert @ti_bob.reload.state?(:AUTHORIZED)

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id], tote_item_states: [ToteItem.states[:ADDED]]}
    assert_equal 0, ActionMailer::Base.deliveries.count
    email = assigns(:email)
    assert email.valid?
    assert_not flash.empty?
    assert_equal "Email object saved but recipient list empty so no emails sent", flash[:info]
    
    assert_response :redirect
    assert_redirected_to email

    #verify bob doesn't get an email
    #verify sam doesn't get an email
    #dont by the ActionMailer::Base.deliveries.count == 0 check above
  end

  test "bob should receive an email when his tote item state matches the selection" do

    #let's make same have a tote item for posting1 as well but make his item state unmatched and then verify that he doesn't get emailed
    ti_sam2 = create_tote_item(@sam, @posting1, 1)
    ti_sam2.update(state: ToteItem.states[:FILLED])
    assert ti_sam2.reload.state?(:FILLED)

    log_in_as(@producer)

    @ti_bob.update(state: ToteItem.states[:NOTFILLED])
    assert @ti_bob.reload.state?(:NOTFILLED)

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id], tote_item_states: [ToteItem.states[:NOTFILLED]]}    
    email = assigns(:email)
    assert email.valid?
    assert_not flash.empty?
    assert_equal "Email successfully sent", flash[:success]
    
    assert_response :redirect
    assert_redirected_to email

    #verify bob does get an email
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries[0]
    assert_equal 1, mail.to.count
    assert_equal @bob.email, mail.to[0]
    assert_equal "mysubject", mail.subject
    assert_match "mybody", mail.body.encoded
    
  end

  test "should send no email if bogus tote item state value posted" do

    #let's make same have a tote item for posting1 as well but make his item state unmatched and then verify that he doesn't get emailed
    ti_sam2 = create_tote_item(@sam, @posting1, 1)
    ti_sam2.update(state: ToteItem.states[:FILLED])
    assert ti_sam2.reload.state?(:FILLED)

    log_in_as(@producer)

    @ti_bob.update(state: ToteItem.states[:NOTFILLED])
    assert @ti_bob.reload.state?(:NOTFILLED)

    ActionMailer::Base.deliveries.clear    
    post emails_path, params: {email: {subject: "mysubject", body: "mybody"}, posting_ids: [@posting1.id], tote_item_states: [ToteItem.states[:NOTFILLED], "bogusstatevalue"]}
    assert_response :redirect
    assert_redirected_to @producer
    assert_not flash.empty?
    assert_equal "Invalid tote item states selected", flash[:danger]
    assert_equal 0, ActionMailer::Base.deliveries.count

  end
  
end