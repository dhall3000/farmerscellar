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

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)
    distributor.update(order_minimum_producer_net: 20)

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save

    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    producer_decoy = create_producer("producer_decoy", "producer_decoy@p.com")
    producer_decoy.create_business_interface(name: producer_decoy.farm_name, order_email_accepted: true, order_email: producer_decoy.email, paypal_accepted: true, paypal_email: producer_decoy.email)

    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1)

    create_commission(producer2, products(:celery), units(:bunch), 0.05)
    posting2 = create_posting(producer2, 2.00, products(:celery), units(:bunch), delivery_date, commitment_zone_start, units_per_case = 1)

    create_commission(producer_decoy, products(:milk), units(:gallon), 0.05)
    posting_decoy = create_posting(producer_decoy, 10.50, products(:milk), units(:gallon), delivery_date_decoy, commitment_zone_start_decoy, units_per_case = 1)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    #both customers order from both distributor postings
    ti1_bob = create_tote_item(bob, posting1, 2)
    ti2_bob = create_tote_item(bob, posting2, 4)

    ti1_sam = create_tote_item(sam, posting1, 1)
    ti2_sam = create_tote_item(sam, posting2, 3)

    #one customer orders from the decoy
    num_decoy_units = 4
    ti_decoy_bob = create_tote_item(bob, posting_decoy, num_decoy_units)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)

    travel_to commitment_zone_start_decoy
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #order should be submitted to decoy producer (but not to the distributor whose orderm in wasn't met)
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

    if false
      #COMMENT KEY: xunrfomunchfve (string search the code for this to find other places where changes are made)
      #FEATURE CHANGE! we used to do it this way. but we're rethinking it. especially here (2016-11-02) in the beginnig of the business we'll
      #be trying to get this bird aloft with little traction. what this means is that when Fila Farms puts a $2,000 order minimum on it might take
      #a very long time for us to hit that min. to mitigate, we're implementing Order Rollover feature. this is going to just be a subscription instance
      #with a special setting so that it turns itself off as soon as it fills once. but consider: what if it takes 3 months to hit Fila's $2K
      #order min with a weekly delivery schedule and that a customer places a "roll till filled" order of quantity 1 with no other FC orders. they'd get
      #peppered each week with a NOTFILLED delivery notification. now imagine this same customer has a similar situation for each of a total of 4 different
      #products, each delivered on a different day between Tuesday - Friday. They'd get 4 emails each week just to tell them their junk isn't here.
      #unacceptable. i want a big bang/buck fix for this so what we're going to do is short circuit any delivery notification emails that only contain
      #NOTFILLED items. a consequence of this is that someone might set-and-forget a roll-till-filled (RTF) order and then forget about it and then when it
      #finally fills it's 9 weeks later when they're on vacation in Hawaii. oh well....let's build it this way and see how often this happens. another
      #reason why i want to implement it this way is because i want people to forget about their RTF orders so they don't think to turn them off. sending them
      #blank NOTFILLED del nots every week will just remind them of the option to cancel their order. of course, another downside is some people might NOT forget
      #and wonder why the radio silence. perhaps we could tell them in the Add to Tote or How Things Work pages.

      #verify delivery notification is correct
      #both customers should get NOT DELIVERED delivery notifications
      #one customer should get DELIVERED delivery notification
      assert_equal 2, ActionMailer::Base.deliveries.count

      bob_mail = ActionMailer::Base.deliveries.first
      assert ti1_bob.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(bob_mail, ti1_bob)
      assert ti2_bob.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(bob_mail, ti2_bob)
      assert ti_decoy_bob.reload.state?(:FILLED)
      #bob's delivery notification email subject should flag that some items aren't filled even though one of his items is filled
      #this is why we have to send the full list of tote items being included in this delivery notification so that the
      #verifier can do the correct logic
      verify_proper_delivery_notification_email(bob_mail, ti_decoy_bob, [ti1_bob, ti2_bob, ti_decoy_bob])
      
      sam_mail = ActionMailer::Base.deliveries.last
      assert ti1_sam.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(sam_mail, ti1_sam)
      assert ti2_sam.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(sam_mail, ti2_sam)
    else
      assert_equal 1, ActionMailer::Base.deliveries.count
      bob_mail = ActionMailer::Base.deliveries.first
      assert ti1_bob.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(bob_mail, ti1_bob)
      assert ti2_bob.reload.state?(:NOTFILLED)
      verify_proper_delivery_notification_email(bob_mail, ti2_bob)
      assert ti_decoy_bob.reload.state?(:FILLED)
      #bob's delivery notification email subject should flag that some items aren't filled even though one of his items is filled
      #this is why we have to send the full list of tote items being included in this delivery notification so that the
      #verifier can do the correct logic
      verify_proper_delivery_notification_email(bob_mail, ti_decoy_bob, [ti1_bob, ti2_bob, ti_decoy_bob])

      #xunrfomunchfve (string search this string for more info)
      #sam now does not get an email because all this tote items are NOTFILLED. see verbose feature-change comment in the if false block above      
      #sam_mail = ActionMailer::Base.deliveries.last
      assert ti1_sam.reload.state?(:NOTFILLED)
      #verify_proper_delivery_notification_email(sam_mail, ti1_sam)
      assert ti2_sam.reload.state?(:NOTFILLED)
      #verify_proper_delivery_notification_email(sam_mail, ti2_sam)
    end

    travel_back

  end

end
