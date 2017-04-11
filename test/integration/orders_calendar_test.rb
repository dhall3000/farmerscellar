require 'integration_helper'

class OrdersCalendarTest < IntegrationHelper

  test "fix erics bug" do
    #scenario: eric orders.e@kapfhammer.info RTF'd a bunch of stuff that all was delivered on the same day. once the order was filled
    #his orders calendar header superscript said '3' but the calendar itself said "you have zero future deliveries". this is weird.

    nuke_all_postings
    nuke_all_users
    producer = create_producer
    posting1 = create_posting(producer, price = 1, product = Product.create(name: "Product1"), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 0.75, important_notes = nil, important_notes_body = nil)
    posting2 = create_posting(producer, price = 2, product = Product.create(name: "Product2"), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1.75, important_notes = nil, important_notes_body = nil)

    bob = create_new_customer("bob", "bob@b.com")
    create_tote_item(bob, posting1, quantity = 1, frequency = nil, roll_until_filled = true)
    create_tote_item(bob, posting2, quantity = 1, frequency = nil, roll_until_filled = true)

    log_in_as bob
    get root_path

    #prior to authorization the calendar header icon superscript shoudl be blank
    assert_select 'span.glyphicon-calendar span.badge', {text: "2", count: 0}
    assert_select 'span.glyphicon-calendar', {text: "", count: 1}
    create_rt_authorization_for_customer(bob)

    #after authorization the calendar header icon superscript should say 2
    log_in_as bob
    get root_path
    assert_select 'span.glyphicon-calendar span.badge', {text: "2", count: 1}

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks
    fully_fill_creditor_order(posting1.creditor_order)

    #after order gets filled the calendar header icon should be blank
    travel 1.minute
    log_in_as bob
    get root_path
    assert_select 'span.glyphicon-calendar', {text: "", count: 1}

    travel_back

  end

  test "calendar display should include filled item" do

    nuke_all_postings

    wednesday_next_week = get_next_wday_after(wday = 3, days_from_now = 7)
    friday_next_week = wednesday_next_week + 2.days

    several_wednesdays_out = wednesday_next_week + 3.weeks
    several_fridays_out = several_wednesdays_out + 2.days

    producer1 = create_producer("producer1", "producer1@p.com")
    producer2 = create_producer("producer2", "producer2@p.com")

    posting1 = create_posting(producer1, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day)
    posting2 = create_posting(producer2, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = posting1.order_cutoff)

    bob = create_user

    ti1 = create_tote_item(bob, posting1, quantity = 1)    
    ti2 = create_tote_item(bob, posting2, quantity = 1)
    
    create_one_time_authorization_for_customer(bob)

    log_in_as(bob)
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'

    tote_items_by_week = assigns(:tote_items_by_week)

    #there should be data for pickups on one week
    assert_equal 1, tote_items_by_week.count

    #this week should have 2 tote items for pickup
    assert_equal 2, tote_items_by_week[0][:tote_items].count
    
    #the delivery dates on these should match like this
    assert_equal posting1.delivery_date, tote_items_by_week[0][:tote_items][0].posting.delivery_date
    assert_equal posting2.delivery_date, tote_items_by_week[0][:tote_items][1].posting.delivery_date

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    assert_equal Posting.states[:COMMITMENTZONE], posting1.reload.state
    assert_equal Posting.states[:COMMITMENTZONE], posting2.reload.state

    fully_fill_creditor_order(posting1.creditor_order)

    log_in_as(bob)
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'

    travel_back

  end

  test "dev driver" do

    nuke_all_postings

    wednesday_next_week = get_next_wday_after(wday = 3, days_from_now = 7)
    friday_next_week = wednesday_next_week + 2.days

    several_wednesdays_out = wednesday_next_week + 3.weeks
    several_fridays_out = several_wednesdays_out + 2.days

    producer1 = create_producer("producer1", "producer1@p.com")
    producer2 = create_producer("producer2", "producer2@p.com")

    posting1 = create_posting(producer1, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day)
    posting11 = create_posting(producer1, price = nil, product = Product.create(name: "Product11"), unit = nil, delivery_date = several_wednesdays_out, order_cutoff = several_wednesdays_out - 1.day)

    posting2 = create_posting(producer2, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = friday_next_week - 1.day)
    posting22 = create_posting(producer2, price = nil, product = Product.create(name: "Product22"), unit = nil, delivery_date = several_fridays_out, order_cutoff = several_fridays_out - 1.day)

    bob = create_user

    create_tote_item(bob, posting1, quantity = 1)
    create_tote_item(bob, posting11, quantity = 1)
    create_tote_item(bob, posting2, quantity = 1)
    create_tote_item(bob, posting22, quantity = 1)

    create_one_time_authorization_for_customer(bob)

    log_in_as(bob)
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'

    tote_items_by_week = assigns(:tote_items_by_week)

    #there should be data for pickups on two different weeks
    assert_equal 2, tote_items_by_week.count

    #each of the two weeks should have 2 tote items for pickup
    assert_equal 2, tote_items_by_week[0][:tote_items].count
    assert_equal 2, tote_items_by_week[1][:tote_items].count

    #the delivery dates on these should match like this
    assert_equal posting1.delivery_date, tote_items_by_week[0][:tote_items][0].posting.delivery_date
    assert_equal posting2.delivery_date, tote_items_by_week[0][:tote_items][1].posting.delivery_date

    assert_equal posting11.delivery_date, tote_items_by_week[1][:tote_items][0].posting.delivery_date
    assert_equal posting22.delivery_date, tote_items_by_week[1][:tote_items][1].posting.delivery_date

  end

  test "calendar should tell user they have no future deliveries" do

    nuke_all_postings
    bob = create_user
    log_in_as(bob)
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'div.text-center', "You have zero future deliveries scheduled."

  end

  test "calendar should tell user they have no future deliveries and invite them to view their ready for pickup page" do

    nuke_all_postings

    wednesday_next_week = get_next_wday_after(wday = 3, days_from_now = 7)
    
    producer1 = create_producer("producer1", "producer1@p.com")
    posting1 = create_posting(producer1, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day)
    bob = create_user
    create_tote_item(bob, posting1, quantity = 1)
    create_one_time_authorization_for_customer(bob)
    log_in_as(bob)
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks
    fully_fill_creditor_order(posting1.creditor_order)

    log_in_as bob
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'div.text-center', "You have zero future deliveries scheduled."
 
    travel_back

  end

  test "fix bansals bug" do
    #bansal_sac@hotmail.com calendar situation: had whole milk that was delivered on thursday week 1.
    #on friday week 1 (the next day) when spoofing his account the header said '2' for orders calendar, which was correct because he had an item set for tuesday delivery.
    #this item set for tuesday delivery was a one-off posting.
    #the calendar itself only rendered week 1 and never rendered week 2.
    #then he added eggs delivery for week 2 and week 2 rendered properly.
    #actually, i just finished implementing this test and i think i might have been smoking crack. it was the end of a stressful day at the end of a stressful week 
    #when i thought i saw this bug and now i can't be sure but it appears to be doing the right thing

    nuke_all_postings
    nuke_all_users

    next_thursday = get_next_wday_after(wday = 4, days_from_now = 7)
    producer = create_producer
    product = Product.create(name: "MyMilk")
    posting1 = create_posting(producer, price = nil, product, unit = nil, delivery_date = next_thursday, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)

    bansal = create_user("bansal", "bansal_sac@hotmail.com")
    create_tote_item(bansal, posting1, quantity = 1, frequency = nil, roll_until_filled = true)

    log_in_as bansal
    get root_path
    assert_select 'span.glyphicon-shopping-cart span.badge', {text: "1", count: 1}
    assert_select 'span.glyphicon-shopping-cart span.badge', {text: "", count: 0}
    assert_select 'span.glyphicon-calendar', {text: "", count: 1}
    assert_select 'span.glyphicon-calendar span.badge', {text: "1", count: 0}
    create_rt_authorization_for_customer(bansal)
    log_in_as bansal
    get root_path
    assert_select 'span.glyphicon-shopping-cart span.badge', {text: "1", count: 0}
    assert_select 'span.glyphicon-shopping-cart', {text: "", count: 1}
    assert_select 'span.glyphicon-calendar span.badge', {text: "1", count: 1}
    assert_select 'span.glyphicon-calendar span.badge', {text: "", count: 0}

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    #now the next item in the series has been generated so header should say '1' for calendar
    log_in_as bansal
    get root_path
    assert_select 'span.glyphicon-shopping-cart span.badge', {text: "1", count: 0}
    assert_select 'span.glyphicon-shopping-cart', {text: "", count: 1}
    assert_select 'span.glyphicon-calendar span.badge', {text: "1", count: 1}
    assert_select 'span.glyphicon-calendar', {text: "", count: 0}

    travel_to posting1.delivery_date + 12.hours

    #milk order got botched, nobody got filled
    fill_posting(posting1, 0)
    
    log_in_as bansal
    get root_path
    #order was rolled until the next week
    assert_select 'span.glyphicon-calendar span.badge', {text: "1", count: 1}

    posting2 = create_posting(producer, price = nil, product, unit = nil, delivery_date = get_next_wday_after(2, 0), order_cutoff = posting1.delivery_date + 1.day + 9.hours, units_per_case = nil, frequency = 0, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)

    create_tote_item(bansal, posting2, quantity = 1)
    create_rt_authorization_for_customer(bansal)
    log_in_as bansal
    get root_path
    #order was rolled until the next week
    assert_select 'span.glyphicon-calendar span.badge', {text: "2", count: 1}

    #now verify the calendar looks appropriate
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'div.thumbnail.horizontal-scroller', 7

    #go to noon on friday after 1st delivery
    travel_to next_thursday + 1.day + 12.hours

  end

end