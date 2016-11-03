require 'test_helper'
require 'integration_helper'

class SubscriptionsRollUntilFilledTest < IntegrationHelper

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
    #create_posting_recurrence(farmer, price, product, unit, delivery_date, commitment_zone_start, units_per_case, frequency)

    pr = create_posting_recurrence
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
    travel_to first_posting.delivery_date + 12.hours
    do_delivery
    assert_equal 0, ActionMailer::Base.deliveries.count

    #6
    ti_sam = sam.tote_items.last
    ti_bob = add_tote_item(bob, second_posting, quantity = 25, frequency = 1)
    create_rt_authorization_for_customer(bob)

    #7
    travel_to second_posting.commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    #verify that order email did get sent
    assert_equal 1, ActionMailer::Base.deliveries.count    
    assert second_posting.reload.state?(:COMMITMENTZONE)
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.first, second_posting.user.get_creditor, second_posting, second_posting.total_quantity_authorized_or_committed, 1, 1)

    travel_to second_posting.delivery_date + 12.hours
    assert_equal 27, second_posting.total_quantity_authorized_or_committed
    fill_posting(second_posting, second_posting.total_quantity_authorized_or_committed)
    ActionMailer::Base.deliveries.clear
    do_delivery
    #two delivery notifications should have gone out
    assert_equal 2, ActionMailer::Base.deliveries.count
    verify_proper_delivery_notification_email(ActionMailer::Base.deliveries.first, ti_bob.reload)
    verify_proper_delivery_notification_email(ActionMailer::Base.deliveries.last, ti_sam.reload)

    #bob's last tote item should be authorized
    assert bob.tote_items.last.state?(:AUTHORIZED)
    assert_equal 3, bob.tote_items.count
    #from here on out sam should have 3 items
    assert_equal 3, sam.tote_items.count
    #sam's last tote item should be removed
    assert sam.tote_items.last.state?(:REMOVED), "state is #{sam.tote_items.last.state.to_s}"
    #sam's subscription should be off
    assert_not sam.tote_items.last.subscription.on

    third_posting = pr.current_posting
    assert_not_equal second_posting, third_posting
    assert third_posting.id > second_posting.id

    travel_to third_posting.commitment_zone_start
    RakeHelper.do_hourly_tasks

    #sam should still have the same number of tote items as the last check cause his subscription should have been turned off
    assert_equal 3, sam.reload.tote_items.count
    #bob, however, should have an additional ti
    assert_equal 4, bob.reload.tote_items.count
    assert bob.tote_items.last.state?(:AUTHORIZED)

    travel_back

  end

end