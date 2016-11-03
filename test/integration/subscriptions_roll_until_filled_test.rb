require 'test_helper'
require 'integration_helper'

class SubscriptionsRollUntilFilledTest < ActionDispatch::IntegrationTest

  test "subscription should regenerate each recurrence until order fills once then cancel subscription" do

    #1producer has an order minimum
    #2bob places just once order
    #3sam places a just once RUF order
    #4however, the sum does not meet the order minimum
    #5so the order is never submitted to the producer
    #6the next cycle bob places a subscription order that bumps the sum up over the OM
    #7both bob and sam should get filled on delivery #2
    #8for delivery #3 sam should not get filled
    #9sam's order should be canceled
    #10bob should continue to get filled.

    nuke_all_postings
    pr = create_posting_recurrence(posting_recurrence_frequency = 1)
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com", 98033)
    sam = create_user("sam", "sam@s.com", 98033)

    ti_bob = add_tote_item(bob, pr.current_posting, quantity = 2, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = add_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)

    first_posting = pr.current_posting
    travel_to first_posting.commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    #verify that order email did not get sent
    assert_equal 0, ActionMailer::Base.deliveries.count    
    assert first_posting.reload.state?(:CLOSED)

    #now verify that second posting has one item for sam and none for bob
    second_posting = pr.reload.current_posting
    assert second_posting.state?(:OPEN)
    assert_equal 1, second_posting.tote_items.count
    assert sam, second_posting.tote_items.first.state?(:AUTHORIZED)
    assert sam, second_posting.tote_items.first.user
    assert second_posting.tote_items.first.subscription
    assert second_posting.tote_items.first.subscription.kind?(:ROLLUNTILFILLED)

    #advance to first_posting delivery date and verify no delivery notifications were sent
    #travel_to first_posting.delivery_date + 12.hours
    #do_delivery
travel_back
next

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