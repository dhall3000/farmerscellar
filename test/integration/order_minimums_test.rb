require 'test_helper'
require 'integration_helper'

class OrderMinimumsTest < IntegrationHelper
  
  test "should not process orders when minimum not met" do
    #bunch of different producers all to one distributor order min not met verify posting is closed and order email not sent and NOT DELIVERED delivery notifications get sent to users

    nuke_all_postings

    delivery_date = get_delivery_date(days_from_now = 10)
    if (delivery_date - 1.day).sunday?
      delivery_date += 1.day
    end
    commitment_zone_start = delivery_date - 2.days

    delivery_date_decoy = delivery_date - 1.day
    commitment_zone_start_decoy = delivery_date_decoy - 2.days

    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "Distributor Inc.")
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)
    distributor.update(order_minimum_producer_net: 20)

    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 farms")
    producer1.distributor = distributor
    producer1.save

    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 farms")
    producer2.distributor = distributor
    producer2.save

    producer_decoy = create_producer("producer_decoy", "producer_decoy@p.com", "WA", 98033, "www.producer_decoy.com", "producer_decoy farms")
    producer_decoy.create_business_interface(name: producer_decoy.farm_name, order_email_accepted: true, order_email: producer_decoy.email, paypal_accepted: true, paypal_email: producer_decoy.email)

    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1)

    create_commission(producer2, products(:celery), units(:bunch), 0.05)
    posting2 = create_posting(producer2, 2.00, products(:celery), units(:bunch), delivery_date, commitment_zone_start, units_per_case = 1)

    create_commission(producer_decoy, products(:milk), units(:gallon), 0.05)
    posting_decoy = create_posting(producer_decoy, 10.50, products(:milk), units(:gallon), delivery_date_decoy, commitment_zone_start_decoy, units_per_case = 1)

    bob = create_user("bob", "bob@b.com", 98033)
    sam = create_user("sam", "sam@s.com", 98033)

    #both customers order from both distributor postings
    ti1_bob = add_tote_item(bob, posting1, 2)
    ti2_bob = add_tote_item(bob, posting2, 4)

    ti1_sam = add_tote_item(sam, posting1, 1)
    ti2_sam = add_tote_item(sam, posting2, 3)

    #one customer orders from the decoy
    num_decoy_units = 4
    ti_decoy = add_tote_item(bob, posting_decoy, num_decoy_units)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)

    travel_to commitment_zone_start_decoy
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #order should be submitted to decoy producer
    assert_equal 1, ActionMailer::Base.deliveries.count
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.last, producer_decoy.get_creditor, posting_decoy, num_decoy_units, units_per_case = "", number_of_cases = "")

    travel_to commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #order should not be submitted to distributor
    assert_equal 0, ActionMailer::Base.deliveries.count    

    #distributor postings should be closed
    assert posting1.reload.state?(:CLOSED)
    assert posting2.reload.state?(:CLOSED)

    #do fill
    travel_to delivery_date_decoy + 12.hours
    fill_posting(posting_decoy.reload, num_decoy_units)    

    #send out delivery notifications
    ActionMailer::Base.deliveries.clear
    do_delivery
    
    #verify delivery notification is correct
    #both customers should get NOT DELIVERED delivery notifications
    #one customer should get DELIVERED delivery notification
    assert_equal 2, ActionMailer::Base.deliveries.count

    bob_mail = ActionMailer::Base.deliveries.first
    assert ti1_bob.reload.state?(:NOTFILLED)
    verify_proper_delivery_notification_email(bob_mail, ti1_bob)
    assert ti2_bob.reload.state?(:NOTFILLED)
    verify_proper_delivery_notification_email(bob_mail, ti2_bob)
    assert ti_decoy.reload.state?(:FILLED)
    #bob's delivery notification email subject should flag that some items aren't filled even though one of his items is filled
    #this is why we have to send the full list of tote items being included in this delivery notification so that the
    #verifier can do the correct logic
    verify_proper_delivery_notification_email(bob_mail, ti_decoy, [ti1_bob, ti2_bob, ti_decoy])
    
    sam_mail = ActionMailer::Base.deliveries.last
    assert ti1_sam.reload.state?(:NOTFILLED)
    verify_proper_delivery_notification_email(sam_mail, ti1_sam)
    assert ti2_sam.reload.state?(:NOTFILLED)
    verify_proper_delivery_notification_email(sam_mail, ti2_sam)

    travel_back

  end

end
