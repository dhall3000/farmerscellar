require 'integration_helper'

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
    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date, order_cutoff = delivery_date - 2.days, units_per_case = 1)    
    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)    
    create_one_time_authorization_for_customer(bob)
    assert ti_bob_carrots.reload.state?(:AUTHORIZED)
    travel_to posting_carrots.order_cutoff
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

    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date, order_cutoff = delivery_date - 2.days, units_per_case = 1)    
    posting_apples  = create_posting(producer, price = 2.50, product = products(:apples), unit = units(:pound), delivery_date2, order_cutoff = delivery_date2 - 2.days, units_per_case = 1)    

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)    
    ti_bob_apples  = create_tote_item(bob, posting_apples , quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_bob_carrots.reload.state?(:AUTHORIZED)
    assert ti_bob_apples.reload.state?(:AUTHORIZED)

    travel_to posting_carrots.order_cutoff
    RakeHelper.do_hourly_tasks
    travel_to posting_apples.order_cutoff
    RakeHelper.do_hourly_tasks

    fully_fill_creditor_order(posting_carrots.creditor_order)

    #verify carrots can be picked up
    travel 1.minute
    assert_equal 0, Pickup.count
    assert_equal 1, bob.reload.tote_items_to_pickup.count
    assert_equal "Carrots", bob.tote_items_to_pickup.first.posting.product.name
    tote_items = do_pickup_for(@dropsite_user, bob.reload, true)
    assert_equal 1, Pickup.count
    assert_equal "Carrots", tote_items.first.posting.product.name

    travel 61.minutes
    #now bob should have zero tote items since it's > 1 hour since last pickup and no additional deliveries have been made.
    tote_items = do_pickup_for(@dropsite_user, bob.reload, true)
    assert_not tote_items.any?
    assert_equal 2, Pickup.count

    fully_fill_creditor_order(posting_apples.creditor_order)

    travel 1.minute
    tote_items = do_pickup_for(@dropsite_user, bob.reload, true)
    assert_equal 1, tote_items.count
    assert_equal "Fuji Apples", tote_items.first.posting.product.name
    assert_equal 3, Pickup.count

    travel 61.minutes
    tote_items = do_pickup_for(@dropsite_user, bob.reload, true)
    assert_not tote_items.any?
    assert_equal 4, Pickup.count

    travel 7.days
    tote_items = do_pickup_for(@dropsite_user, bob.reload, true)
    assert_nil tote_items
    
    travel_back

  end

  test "user should see clear messaging whenever not all items are fully filled" do

    nuke_all_postings

    producer = create_producer("producer", "producer@o.com")
    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots))
    posting_apples  = create_posting(producer, price = 2.50, product = products(:apples))

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)    
    ti_bob_apples  = create_tote_item(bob, posting_apples , quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_bob_carrots.reload.state?(:AUTHORIZED)
    assert ti_bob_apples.reload.state?(:AUTHORIZED)

    travel_to posting_carrots.order_cutoff
    RakeHelper.do_hourly_tasks
    fully_fill_creditor_order(posting_carrots.creditor_order)

    #both items should be fully filled as of now
    assert_equal ti_bob_carrots.reload.quantity, ti_bob_carrots.quantity_filled
    assert ti_bob_carrots.state?(:FILLED)
    assert_equal ti_bob_apples.reload.quantity, ti_bob_apples.quantity_filled
    assert ti_bob_apples.state?(:FILLED)

    #now make the carrots not fully filled so we can proceed with our test
    ti_bob_carrots.update(quantity_filled: 3)
    assert_equal 3, ti_bob_carrots.quantity_filled
    assert ti_bob_carrots.partially_filled?

    do_pickup_for(@dropsite_user, bob.reload)

    travel_back

  end

  test "zero filled items should not show up in the ready for pickup list or on the kiosk display" do

    nuke_all_postings
    posting1 = create_posting(farmer = nil, price = 1.04, product = Product.create(name: "Product1"), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)
    posting2 = create_posting(farmer = posting1.user, price = 1.04, product = Product.create(name: "Product2"), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 10, product_id_code = nil, producer_net_unit = 1)

    assert_equal posting1.order_cutoff, posting2.order_cutoff
    assert_equal posting1.delivery_date, posting2.delivery_date

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_posting1 = create_tote_item(bob, posting1, quantity = 2)    
    ti_posting2 = create_tote_item(bob, posting2, quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_posting1.reload.state?(:AUTHORIZED)
    assert ti_posting2.reload.state?(:AUTHORIZED)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti_posting1.reload.state?(:COMMITTED)
    assert ti_posting2.reload.state?(:NOTFILLED)

    fully_fill_creditor_order(posting1.creditor_order)

    assert ti_posting1.reload.state?(:FILLED)

    do_pickup_for(@dropsite_user, bob.reload)

    travel_back

  end

  #this is a port form bulk_purchases_test. using updated test technology now. old test was causing problems. i think the intent was just to drive development of the pickup features
  test "do pickups" do
    
    nuke_all_postings

    wednesday_next_week = get_next_wday_after(3, days_from_now = 7)

    producer1 = create_producer("producer1", email = "producer1@p.com")
    producer2 = create_producer("producer2", email = "producer2@p.com")

    #order cutoff tuesday, delivery wednesday
    posting1 = create_posting(producer1, price = 1.04, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)
    #order cutoff thursday, delivery friday
    posting2 = create_posting(producer2, price = 1.04, product = Product.create(name: "Product2"), unit = nil, delivery_date = wednesday_next_week + 2.days, order_cutoff = wednesday_next_week + 1.day, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)

    assert_not_equal posting1.order_cutoff, posting2.order_cutoff
    assert_not_equal posting1.delivery_date, posting2.delivery_date

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_posting1 = create_tote_item(bob, posting1, quantity = 2)    
    ti_posting2 = create_tote_item(bob, posting2, quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_posting1.reload.state?(:AUTHORIZED)
    assert ti_posting2.reload.state?(:AUTHORIZED)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks
    assert ti_posting1.reload.state?(:COMMITTED)
    fully_fill_creditor_order(posting1.creditor_order)
    assert ti_posting1.reload.state?(:FILLED)

    travel_to posting2.order_cutoff
    RakeHelper.do_hourly_tasks
    assert ti_posting2.reload.state?(:COMMITTED)

    #user picks up on thursday which is between the W and F deliveries
    travel_to wednesday_next_week + 1.day + 12.hours
    tote_items_picked_up = do_pickup_for(@dropsite_user, bob.reload, true)
    assert tote_items_picked_up.count < bob.tote_items.count
    num_items_first_pickup_count = tote_items_picked_up.count
    assert num_items_first_pickup_count > 0

    fully_fill_creditor_order(posting2.reload.creditor_order)
    assert ti_posting2.reload.state?(:FILLED)

    #jump to one day after the last delivery day
    travel_to posting2.delivery_date + 1.day + 12.hours
    num_items_second_pickup_count = bob.tote_items_to_pickup.count
    assert num_items_second_pickup_count > 0   
    assert_equal bob.tote_items.count, num_items_first_pickup_count + num_items_second_pickup_count

    #now verify that if user never comes to pick up second ti that it's will get cleared out
    travel_to Time.zone.now + 7.days
    assert_equal 0, bob.tote_items_to_pickup.count

    #jump back to one day after the last delivery date
    travel_to posting2.delivery_date + 1.day + 12.hours
    tote_items_picked_up = do_pickup_for(@dropsite_user, bob.reload, true) 
    assert_equal num_items_second_pickup_count, tote_items_picked_up.count
    assert tote_items_picked_up.count > 0

    travel 61.minutes
    tote_items_picked_up = do_pickup_for(@dropsite_user, bob.reload, true)
    #verify no more items picked up
    assert_equal 0, tote_items_picked_up.count

    travel_back
  end

  test "pickups should notify user of partially filled items" do
    nuke_all_postings

    wednesday_next_week = get_next_wday_after(3, days_from_now = 7)

    posting1 = create_posting(producer = nil, price = 1.04, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)
    posting2 = create_posting(posting1.user, price = 1.04,  product = Product.create(name: "Product2"), unit = nil, posting1.delivery_date, posting1.order_cutoff, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)

    assert_equal posting1.order_cutoff, posting2.order_cutoff
    assert_equal posting1.delivery_date, posting2.delivery_date

    bob = create_user("bob", "bob@b.com")
    bob.set_dropsite(Dropsite.first)    

    ti_posting1 = create_tote_item(bob, posting1, quantity = 2)    
    ti_posting2 = create_tote_item(bob, posting2, quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_posting1.reload.state?(:AUTHORIZED)
    assert ti_posting2.reload.state?(:AUTHORIZED)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti_posting1.reload.state?(:COMMITTED)
    assert ti_posting2.reload.state?(:COMMITTED)

    fully_fill_creditor_order(posting1.creditor_order)

    assert ti_posting1.reload.state?(:FILLED)
    assert ti_posting2.reload.state?(:FILLED)

    #hack ti2 so it's only partially filled
    ti_posting2.update(quantity_filled: ti_posting2.quantity - 1)
    assert ti_posting2.partially_filled?

    travel 1.minute
    tote_items_picked_up = do_pickup_for(@dropsite_user, bob.reload)
    assert_equal 2, tote_items_picked_up.count

    travel_back

  end

  test "pickup list should say deadline is tomorrow or today appropriately" do
  end

end