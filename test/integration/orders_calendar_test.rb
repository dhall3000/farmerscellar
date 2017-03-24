require 'integration_helper'

class OrdersCalendarTest < IntegrationHelper

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
 
    assert_select 'a', "ready for pickup"

    travel_back

  end


end