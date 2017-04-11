require 'integration_helper'

class HeaderTest < IntegrationHelper

  test "verify rtf order does not show two items during committment window" do
    
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    bob = create_user("bob", "bob@b.com")

    assert_not bob.dropsite.nil?

    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = true)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' authorize his subscription and verify 'tote' link no longer says '1', orders and calendar do say '1'
    log_in_as bob
    create_rt_authorization_for_customer(bob)
    assert_response :success
    verify_header(tote = 0, orders = 1, calendar = 1, subscriptions = 0, ready_to_pickup = 0)

    #now go to order cutoff and transition to committment zone
    travel_to ti.posting.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti.reload.state?(:COMMITTED)

    #travel to the middle of committment zone
    travel 1.day
    log_in_as bob
    assert_response :redirect
    follow_redirect!

    #orders = 3 is wonky but not going to fix it because we're going to yank it soon. it's the calendar we want to verify is correct
    verify_header(tote = 0, orders = 2, calendar = 1, subscriptions = 0, ready_to_pickup = 0)
    calendar_items = ToteItemsController.helpers.future_items(ToteItem.calendar_items_displayable(bob))
    assert_equal 1, calendar_items.count
    assert_equal ti.posting.delivery_date, calendar_items.first.posting.delivery_date    

    #now fill the order
    fully_fill_creditor_order(ti.posting.creditor_order)
    travel 1.minute

    log_in_as bob
    assert_response :redirect
    follow_redirect!
    #so after delivery bob should see orders 2 (wonky and doomed as it is), one for the subscription and one for the next deliverable item which will be 6 days from now.
    #calendar should be 1, which would be the delivery 6 days from now. and of course ready to pickup 1 cause yesterday's fill
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 1)

    #now bob does a pickup
    assert_equal 0, bob.reload.pickups.count
    do_pickup_for(users(:dropsite1), bob.reload, true)
    assert_equal 1, bob.reload.pickups.count
    #then logs in to his account...

    log_in_as bob
    assert_response :redirect
    follow_redirect!
    
    #when he looks at his header he's still going to see ready to pickup 1 cause we have to wait until the nightly tasks dirties up his user header bit
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 1)
    #even one hour later he'll still see ready for pickup 1 because we don't dirty up his user object until 10pm with the rake nightly tasks
    travel 1.hour
    get root_path
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 1)
    travel 1.hour
    get root_path
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 1)

    #now go to 10pm and do the nightly tasks, then verify user sees 0 ready for pickup
    travel_to Time.zone.now.midnight + 22.hours
    RakeHelper.do_hourly_tasks

    assert bob.reload.header_data_dirty
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    travel_back

  end

  test "verify subscription does not show two items during committment window" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    create_tote_item(chris, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 2, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_rt_authorization_for_customer(chris)
    assert_response :success
    verify_header(tote = 0, orders = 4, calendar = 2, subscriptions = 2, ready_to_pickup = 0)

    #now have 'bob' authorize his subscription and verify 'tote' link no longer says '1', orders and calendar do say '1'
    log_in_as bob
    create_rt_authorization_for_customer(bob)
    assert_response :success
    verify_header(tote = 0, orders = 2, calendar = 1, subscriptions = 1, ready_to_pickup = 0)

    #now go to order cutoff and transition to committment zone
    travel_to ti.posting.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti.reload.state?(:COMMITTED)

    #travel to the middle of committment zone
    travel 1.day
    log_in_as bob
    assert_response :redirect
    follow_redirect!

    #orders = 3 is wonky but not going to fix it because we're going to yank it soon. it's the calendar we want to verify is correct
    verify_header(tote = 0, orders = 3, calendar = 1, subscriptions = 1, ready_to_pickup = 0)
    calendar_items = ToteItemsController.helpers.future_items(ToteItem.calendar_items_displayable(bob))
    assert_equal 1, calendar_items.count
    assert_equal ti.posting.delivery_date, calendar_items.first.posting.delivery_date    

    #now fill the order
    fully_fill_creditor_order(ti.posting.creditor_order)
    travel 1.minute

    log_in_as bob
    assert_response :redirect
    follow_redirect!
    #so after delivery bob should see orders 2 (wonky and doomed as it is), one for the subscription and one for the next deliverable item which will be 6 days from now.
    #calendar should be 1, which would be the delivery 6 days from now. and of course ready to pickup 1 cause yesterday's fill
    verify_header(tote = 0, orders = 2, calendar = 1, subscriptions = 1, ready_to_pickup = 1)
    #verify the calendar item really is for the next week's delivery
    calendar_items = ToteItemsController.helpers.future_items(ToteItem.calendar_items_displayable(bob))
    assert_equal 1, calendar_items.count
    assert_equal ti.posting.delivery_date + 1.week, calendar_items.first.posting.delivery_date
    assert_equal ti.reload.subscription.latest_delivery_date_item.posting.delivery_date, calendar_items.first.posting.delivery_date

    travel_back

  end

  test "verify subscription value correct after addition and removal" do
    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = 1, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' authorize his subscription and verify 'tote' link no longer says '1', orders and calendar do say '1'
    log_in_as bob
    create_rt_authorization_for_customer(bob)
    assert_response :success
    verify_header(tote = 0, orders = 2, calendar = 1, subscriptions = 1, ready_to_pickup = 0)

    #now have bob nuke his order
    patch subscription_path(ti.subscription), params: {subscription: {on: 0}}
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)            
  end

  test "verify tote superscript accurate after order cancelation" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' authorize his item and verify 'tote' link no longer says '1', orders and calendar do say '1'
    create_rt_authorization_for_customer(bob)
    assert_response :success        
    verify_header(tote = 0, orders = 1, calendar = 1, subscriptions = 0, ready_to_pickup = 0)

    #now have bob nuke his order
    delete tote_item_path(ti.reload)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)        

  end

  test "verify tote superscript accurate after tote item rtauthorization" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' authorize his item and verify 'tote' link no longer says '1'
    create_rt_authorization_for_customer(bob)
    assert_response :success        
    verify_header(tote = 0, orders = 1, calendar = 1, subscriptions = 0, ready_to_pickup = 0)        

  end

  test "verify tote superscript accurate after tote item one time authorization" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' authorize his item and verify 'tote' link no longer says '1'
    create_one_time_authorization_for_customer(bob)
    assert_response :success        
    verify_header(tote = 0, orders = 1, calendar = 1, subscriptions = 0, ready_to_pickup = 0)        

  end

  test "verify tote superscript accurate for tote item removals" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    ti = create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now have 'bob' remove his item and verify 'tote' link no longer says '1'
    delete tote_item_path(ti)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)        

  end

  test "verify tote superscript accurate for tote item additions" do

    nuke_all_users
    nuke_all_postings

    #make a simple non-recurring posting and have 'bob' add a single tote item to it
    #then verify his tote header link has the right value
    posting = create_posting
    bob = create_user("bob", "bob@b.com")
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

    #now make a new user 'chris', have him add one tote item, then verify bob's header is still accurate
    chris = create_user("chris", "chris@c.com")
    log_in_as chris
    assert_response :redirect
    follow_redirect!
    verify_header(tote = 0, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    create_tote_item(chris, posting, quantity = 1, frequency = nil, roll_until_filled = nil)
    assert_response :redirect
    follow_redirect!    
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)
    log_in_as bob
    follow_redirect!
    verify_header(tote = 1, orders = 0, calendar = 0, subscriptions = 0, ready_to_pickup = 0)

  end

  test "number of active authorized subscriptions should be accurate" do
    bob = create_user
    #should report 0
    log_in_as bob
    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_template '/'

    #verify no subscriptions indicated
    assert_select 'span.glyphicon-repeat', ""
    #add a non-recurring tote item
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil)
    ti = create_tote_item(bob, posting, quantity = 1)
    assert ti.valid?
    assert_response :redirect
    follow_redirect!
    #verify tote item shows in header
    assert_select 'span.glyphicon-shopping-cart span.badge', "1"
    #verify we do not see a subscription
    assert_select 'span.glyphicon-repeat', ""
    #add sx to tote
    ti2 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should report 0
    assert_select 'span.glyphicon-repeat', ""
    assert_equal 0, num_authorized_subscriptions_for(bob)
    #create authorization
    create_rt_authorization_for_customer(bob)
    #should report 1    
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat span.badge', "1"
    #add another subscription to tote
    ti3 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should still only be one authorized subscription
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat span.badge', "1"
    #now authorize and then verify there are two subscriptions
    create_rt_authorization_for_customer(bob)    
    assert_equal 2, num_authorized_subscriptions_for(bob)
    assert_select 'span.glyphicon-repeat span.badge', "2"
    #cancel first sx
    patch subscription_path(ti2.subscription), params: {subscription: {on: 0}}
    assert_response :redirect
    follow_redirect!
    #should report 1
    assert_equal 1, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat span.badge', "1"    
    #cancel second sx

    patch subscription_path(ti3.subscription), params: {subscription: {on: 0}}
    assert_response :redirect
    follow_redirect!    
    #should report 0
    assert_equal 0, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat', ""

    #now create a RTF order and verify this doesn't change the subscription count
    create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(bob)    
    assert_equal 0, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat', ""

  end

  test "ready for pickup link should display correct number" do
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

    #header should not display a number since there are zero items ready for pickup
    assert_select 'span.glyphicon-ok', ""

    assert ti_posting1.reload.state?(:AUTHORIZED)
    assert ti_posting2.reload.state?(:AUTHORIZED)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti_posting1.reload.state?(:COMMITTED)
    assert ti_posting2.reload.state?(:COMMITTED)

    fully_fill_creditor_order(posting1.creditor_order)
    travel 1.minute

    assert ti_posting1.reload.state?(:FILLED)
    assert ti_posting2.reload.state?(:FILLED)

    log_in_as bob
    assert_response :redirect
    follow_redirect!
    #header should now display there are 2 items ready for pickup
    assert_select 'span.glyphicon-ok span.badge', "2"
    do_pickup_for(users(:dropsite1), bob.reload, true)
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    assert_select 'span.glyphicon-ok span.badge', "2"

    travel 61.minutes
    log_in_as bob
    assert_response :redirect
    follow_redirect!
    #header should not display a number since there are zero items ready for pickup
    #since user just picked them up
    assert_select 'span.glyphicon-ok', ""

    travel_back    
  end

  test "orders calendar superscript should be correct" do
    nuke_all_postings
    wednesday_next_week = get_next_wday_after(3, days_from_now = 7)

    producer1 = create_producer(name = "producer1", email = "producer1@p.com")
    producer2 = create_producer(name = "producer2", email = "producer2@p.com")

    #recurring posting1 delivery on wednesday
    posting1 = create_posting(producer1, price = 1.04, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day, units_per_case = nil, frequency = 1)
    #recurring posting2 delivery on thursday
    posting2 = create_posting(producer2, price = 1.04, product = Product.create(name: "Product2"), unit = nil, delivery_date = wednesday_next_week + 1.day, order_cutoff = wednesday_next_week - 1.day, units_per_case = nil, frequency = 1)
    
    bob = create_user
    #user has every-other-week subscription for wednesday posting
    ti1 = create_tote_item(bob, posting1, quantity = 1, frequency = 2)
    #user has every week subscription for thursday posting
    ti2 = create_tote_item(bob, posting2, quantity = 1, frequency = 1)

    create_rt_authorization_for_customer(bob)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    fully_fill_creditor_order(posting1.creditor_order)

    travel 1.minute

    log_in_as bob
    assert_response :redirect
    follow_redirect!    

    #the every other week subscription won't have a future item generated until the next order cutoff hits. so the only item is the one that just got filled. however,
    #the header only shows future items. we want it this way so that people use the ready to pickup feature for pickups rather than the calendar. the reason for this is
    #using the ready for pickup feature on one's mobile device in the dropsite while picking up should drive down SNAFU rate. so calendar only shows future deliverables.
    #so right now for the every-other-week series there are no future items yet. for the weekly subscription there should be tomorrow's item displayed.
    assert_select 'span.glyphicon-calendar span.badge', "1"

    travel_back
    
  end

end