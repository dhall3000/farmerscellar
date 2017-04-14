require 'authorization_helper'

class AuthorizationsTest < Authorizer

  test "dev driver" do
    
    nuke_all_postings
    posting = create_posting
    posting2 = create_posting(posting.user, price = nil, product = Product.create(name: "Product2"))
    customer = create_new_customer
    create_tote_item(customer, posting, quantity = 1)
    create_tote_item(customer, posting2, quantity = 1)
    auth = create_one_time_authorization_for_customer(customer)

    create_tote_item(customer, posting, quantity = 1)
    create_tote_item(customer, posting2, quantity = 1)
    rtauth = create_rt_authorization_for_customer(customer)

    log_in_as customer
    get rtauthorizations_path

  end

  test "make sure rtf order only displays one item at a time" do

    nuke_all_postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    
    customer = create_new_customer
    ti = create_tote_item(customer, posting1, quantity = 1, frequency = nil, roll_until_filled = true)
    rtauth = create_rt_authorization_for_customer(customer)
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)

    #there should be a single auth'd item before the first order cutoff
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti1 = tote_items.first
    assert ti1.state?(:AUTHORIZED)
    assert_equal posting1.delivery_date, ti1.posting.delivery_date

    #there should be zero '@subscriptions'
    assert_equal 0, assigns(:subscriptions).count

    #now go to first order cutoff
    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    #there should be only one item and it should be committed
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti2 = tote_items.first
    assert ti2.state?(:COMMITTED)
    assert_equal ti1, ti2

    #now go to delivery day. posting doesn't get filled so there should only be one authorized item
    travel_to posting1.delivery_date + 12.hours
    fill_posting(posting1, quantity = 0)
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti3 = tote_items.first
    assert ti3.state?(:AUTHORIZED)
    assert_not_equal ti2, ti3

    #now go to 2nd order cutoff and there still should be one item
    travel_to ti3.posting.order_cutoff
    RakeHelper.do_hourly_tasks    
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti4 = tote_items.first
    assert ti4.state?(:COMMITTED)

    #now travel to 2nd delivery day and fill and there should only be a single item and it should be filled
    fully_fill_creditor_order(ti3.posting.creditor_order)    
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti5 = tote_items.first
    assert ti5.reload.state?(:FILLED)
    assert_equal ti4, ti5

    #then go to the 3rd order cutoff and the fetched item should == ti5
    rtauth.reload
    ti_last = rtauth.tote_items.joins(:posting).order("postings.delivery_date").last
    assert ti_last.state?(:REMOVED)
    assert_equal ti4.posting.delivery_date + 7.days, ti_last.posting.delivery_date
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti_done = tote_items.first
    assert ti_done.reload.state?(:FILLED)
    assert_equal ti5, ti_done

  end

  #this should create an auth in the db for each customer that has tote items
  test "should create new authorizations" do
    puts "test: should create new authorizations"
    #first verify there are currently no auths in the db
    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)

  end

end