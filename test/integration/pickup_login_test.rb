require 'test_helper'
require 'integration_helper'
require 'utility/rake_helper'

class PickupLoginTest < IntegrationHelper

	def setup
    @user = users(:c1)
    @other_user = users(:c2)    
    @dropsite_user = users(:dropsite1)
  end

  test "dropsite user should log in" do    
    log_in_as(@dropsite_user)
    assert :success
  end

  test "should get pickup login page when logging in as dropsite user" do
    log_in_dropsite_user(@dropsite_user)
  end

  test "items delivered on wednesday should not be available for pickup next tuesday" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    travel_to bob.tote_items.first.posting.delivery_date + 6.days    
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back    

  end

  test "items picked up 30 minutes ago should still be available for pickup" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    assert_equal 2, bob.pickups.count
    travel_to Time.zone.now + 30.minutes
    assert_equal 1, bob.tote_items_to_pickup.count

    travel_back

  end

  test "items picked up 90 minutes ago should not still be available for pickup" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    assert_equal 2, bob.pickups.count
    travel_to Time.zone.now + 90.minutes
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back

  end

  test "items delivered on wednesday should be available for pickup on thursday" do    

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    travel_to Time.zone.now + 61.minutes
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back

  end

  def setup_pickup_testing
    
    nuke_all_postings
    producer = create_producer("producer", "producer@o.com")
    producer.save
    delivery_date = get_delivery_date(days_from_now = 14)
    days_shift = delivery_date.wday - 3
    delivery_date = delivery_date - days_shift.days
    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date, commitment_zone_start = delivery_date - 2.days, units_per_case = 1)    
    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)    
    create_one_time_authorization_for_customer(bob)
    assert ti_bob_carrots.reload.state?(:AUTHORIZED)
    travel_to posting_carrots.commitment_zone_start
    now = Time.zone.now
    RakeHelper.do_hourly_tasks
    assert ti_bob_carrots.reload.state?(:COMMITTED)
    travel_to posting_carrots.delivery_date + 12.hours
    fully_fill_all_creditor_orders
    assert ti_bob_carrots.reload.state?(:FILLED)

    travel_to now

    return bob

  end

  test "second pickup of the week should not display items picked up during first pickup" do

    nuke_all_postings
    producer = create_producer("producer", "producer@o.com")
    producer.save
    delivery_date = get_delivery_date(days_from_now = 14)    
    days_shift = delivery_date.wday - 3
    delivery_date = delivery_date - days_shift.days
    delivery_date2 = delivery_date + 2.days

    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date, commitment_zone_start = delivery_date - 2.days, units_per_case = 1)    
    posting_apples  = create_posting(producer, price = 2.50, product = products(:apples), unit = units(:pound), delivery_date2, commitment_zone_start = delivery_date2 - 2.days, units_per_case = 1)    

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)    
    ti_bob_apples  = create_tote_item(bob, posting_apples , quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_bob_carrots.reload.state?(:AUTHORIZED)
    assert ti_bob_apples.reload.state?(:AUTHORIZED)

    travel_to posting_carrots.commitment_zone_start
    RakeHelper.do_hourly_tasks
    travel_to posting_apples.commitment_zone_start
    RakeHelper.do_hourly_tasks

    fully_fill_creditor_order(posting_carrots.creditor_order)

    #verify carrots can be picked up
    travel 1.minute
    assert_equal 0, Pickup.count
    assert_equal 1, bob.reload.tote_items_to_pickup.count
    assert_equal "Carrots", bob.tote_items_to_pickup.first.posting.product.name
    tote_items = do_pickup_for(@dropsite_user, bob.reload)
    log_out_dropsite_user
    assert_equal 1, Pickup.count
    assert_equal "Carrots", tote_items.first.posting.product.name

    travel 61.minutes
    #now bob should have zero tote items since it's > 1 hour since last pickup and no additional deliveries have been made.
    tote_items = do_pickup_for(@dropsite_user, bob.reload)
    log_out_dropsite_user
    assert_not tote_items.any?
    assert_equal 2, Pickup.count

    fully_fill_creditor_order(posting_apples.creditor_order)

    travel 1.minute
    tote_items = do_pickup_for(@dropsite_user, bob.reload)
    log_out_dropsite_user
    assert_equal 1, tote_items.count
    assert_equal "Fuji Apples", tote_items.first.posting.product.name
    assert_equal 3, Pickup.count

    travel 61.minutes
    tote_items = do_pickup_for(@dropsite_user, bob.reload)
    log_out_dropsite_user
    assert_not tote_items.any?
    assert_equal 4, Pickup.count

    travel 7.days
    tote_items = do_pickup_for(@dropsite_user, bob.reload)
    assert_template 'pickups/new'
    log_out_dropsite_user

    travel_back

  end

end