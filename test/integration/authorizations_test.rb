require 'authorization_helper'

class AuthorizationsTest < Authorizer

  test "user should still see authorization even if they cancel subscription right after creating it" do

    nuke_all_postings

    #create postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)

    #create customer, subscription and authorization    
    customer = create_new_customer
    sx1 = create_tote_item(customer, posting1, quantity = 1, frequency = 1, roll_until_filled = false).subscription
    assert sx1.valid?
    rtauth1 = create_rt_authorization_for_customer(customer)        

    #user logs in to view auth
    log_in_as customer
    get rtauthorization_path(rtauth1, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    sx = subscriptions.first
    assert_equal sx1, sx

    #user then cancels the subscription
    assert sx1.reload.on
    patch subscription_path(sx1), params: {subscription: {on: 0}}
    assert_not sx1.reload.on

    #user then tries to view the authorization again
    get rtauthorization_path(rtauth1, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    sx = subscriptions.first
    assert_equal sx1, sx
    
  end

  test "user should still see authorization even if they cancel item right after creating it" do
    nuke_all_postings

    #create postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)

    #create customer, tote item and authorization    
    customer = create_new_customer
    ti1 = create_tote_item(customer, posting1, quantity = 1, frequency = 0, roll_until_filled = true)
    assert ti1.valid?
    rtauth1 = create_rt_authorization_for_customer(customer)        

    #user logs in to view auth
    log_in_as customer
    get rtauthorization_path(rtauth1, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 1, tote_items.count
    ti = tote_items.first
    assert_equal ti1, ti

    #user then cancels the tote item
    assert ti1.reload.state?(:AUTHORIZED)
    delete tote_item_path(ti1)
    assert ti1.reload.state?(:REMOVED)

    #user then tries to view the authorization again
    get rtauthorization_path(rtauth1, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 1, tote_items.count
    ti = tote_items.first
    assert_equal ti1, ti
    
  end

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
    assert ti3.reload.state?(:NOTFILLED)
    assert_equal ti2, ti3

    #now go to 2nd order cutoff and there still should be one item
    next_posting = ti3.reload.posting.posting_recurrence.current_posting
    travel_to next_posting.order_cutoff    
    RakeHelper.do_hourly_tasks    
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti4 = tote_items.first
    assert ti4.state?(:NOTFILLED)

    #now travel to 2nd delivery day and fill and there should only be a single item and it should be filled
    fully_fill_creditor_order(next_posting.creditor_order)
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti5 = tote_items.first
    assert ti5.reload.state?(:NOTFILLED)
    assert_equal ti4, ti5

    #then go to the 3rd order cutoff and the fetched item should == ti5
    rtauth.reload
    ti_last = rtauth.tote_items.joins(:posting).order("postings.delivery_date").last
    assert ti_last.state?(:REMOVED)
    #assert_equal ti4.posting.delivery_date + 7.days, ti_last.posting.delivery_date
    log_in_as customer
    get rtauthorization_path(rtauth, rta: 1)
    tote_items = assigns(:tote_items)
    assert_equal 1, tote_items.count
    ti_done = tote_items.first
    assert ti_done.reload.state?(:NOTFILLED)
    assert_equal ti5, ti_done

  end

  test "user should see only one subscription on each of two different auth show views" do

    nuke_all_postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    
    customer = create_new_customer
    sx1 = create_tote_item(customer, posting1, quantity = 1, frequency = 1, roll_until_filled = false).subscription
    assert sx1.valid?
    rtauth1 = create_rt_authorization_for_customer(customer)
    sx2 = create_tote_item(customer, posting2, quantity = 1, frequency = 1, roll_until_filled = false).subscription
    assert sx2.valid?
    rtauth2 = create_rt_authorization_for_customer(customer)
    log_in_as customer

    #when viewing auth1 user should only see sx1
    get rtauthorization_path(rtauth1, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    sx = subscriptions.first
    assert_equal sx1, sx

    #when viewing auth2 user should only see sx2
    get rtauthorization_path(rtauth2, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    sx = subscriptions.first
    assert_equal sx2, sx

    #sx1 should have two authorizations
    assert_equal 2, sx1.rtauthorizations.count
    #sx2 should have one authorization
    assert_equal 1, sx2.rtauthorizations.count

    #there should be one tote item to look at...the one generated by sx2
    assert_equal 1, assigns(:tote_items).count

  end

  test "items should show up on different authorization show pages" do
    #the very first authorization made is a one-time authorization. But then before the order cut off hits that person decides to authorize a subscription and a
    #different one time authorization. Something like that. The idea is that this would create two different authorizations when the user goes to their authorizations
    #index page they should see two rows when they click on the first authorization it should display only that first one time item then when they go back
    #to the index and click the second authorization they should then see the subscription and the second one time item but they should not see the first
    #one time item even though that item will be associated with the second authorization

    nuke_all_postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting3 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product3"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    
    customer = create_new_customer

    #create first one time item
    ti1 = create_tote_item(customer, posting1, quantity = 1, frequency = nil, roll_until_filled = false)
    assert_not ti1.subscription

    #now make one time auth
    auth1 = create_one_time_authorization_for_customer(customer)
    assert_equal flash[:success], "Checkout successful"
    assert auth1.valid?

    #create 2nd one time item
    ti2 = create_tote_item(customer, posting2, quantity = 1, frequency = nil, roll_until_filled = false)
    assert_not ti2.subscription

    #create subscription
    sx = create_tote_item(customer, posting2, quantity = 1, frequency = 1, roll_until_filled = false).subscription

    #and now create rt auth
    auth2 = create_rt_authorization_for_customer(customer)

    #now let's go peruse the auth pages and verify things look good
    log_in_as customer
    get rtauthorizations_path
    assert_response :success
    assert_template 'rtauthorizations/index'

if false
#for an explanation of this commented out block, see the wordy comments in rtauthorizationscontroller#index above this line of code:
#@all_auths = @rtauthorizations
#this if false'd out block would work save for that hack hack
    authorizations = assigns(:authorizations)
    assert authorizations
    assert authorizations.any?
    assert_equal 1, authorizations.count
    assert_equal auth1, authorizations.first
end

    rtauths = assigns(:rtauthorizations)
    assert rtauths
    assert rtauths.any?
    assert_equal 1, rtauths.count
    assert_equal auth2, rtauths.first

    #now let's examine auth1 and verify data looks good
    get rtauthorization_path(auth1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    #there should be no subscriptions
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert_not subscriptions.any?
    #there should be one tote item and it should equal ti1
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 1, tote_items.count
    tote_item = tote_items.first
    assert_equal ti1, tote_item

    #now let's examine auth2 and verify data looks good
    get rtauthorization_path(auth2, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    #there should be one subscription
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    #there should be two tote items...ti2 and the one generated by sx
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 2, tote_items.count
    tote_item = tote_items.last
    assert_equal ti2, tote_item
    tote_item = tote_items.first
    assert_equal sx.tote_items.first, tote_item
  end

  test "items should show up on different authorization show pages 2" do
    #the very first authorization made is a one-time authorization. But then before the order cut off hits that person decides to authorize a subscription and a
    #different one time authorization. Something like that. The idea is that this would create two different authorizations when the user goes to their authorizations
    #index page they should see two rows when they click on the first authorization it should display only that first one time item then when they go back
    #to the index and click the second authorization they should then see the subscription and the second one time item but they should not see the first
    #one time item even though that item will be associated with the second authorization

    nuke_all_postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting3 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product3"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    
    customer = create_new_customer

    #create first one time item
    ti1 = create_tote_item(customer, posting1, quantity = 1, frequency = nil, roll_until_filled = false)
    assert_not ti1.subscription

    #now make one time auth
    auth1 = create_one_time_authorization_for_customer(customer)
    assert_equal flash[:success], "Checkout successful"
    assert auth1.valid?

    #create 2nd one time item
    ti2 = create_tote_item(customer, posting2, quantity = 1, frequency = nil, roll_until_filled = false)
    assert_not ti2.subscription

    #create subscription
    sx1 = create_tote_item(customer, posting2, quantity = 1, frequency = 1, roll_until_filled = false).subscription
    assert sx1.valid?
    assert_equal 1, sx1.tote_items.count
    sxti1 = sx1.tote_items.first

    #and now create rt auth
    auth2 = create_rt_authorization_for_customer(customer)

    #now create objects for auth3
    ti3 = create_tote_item(customer, posting1, quantity = 1, frequency = nil, roll_until_filled = false)
    assert_not ti3.subscription
    sx2 = create_tote_item(customer, posting2, quantity = 1, frequency = 1, roll_until_filled = false).subscription
    assert sx2.valid?
    assert_equal 1, sx2.tote_items.count
    sxti2 = sx2.tote_items.first

    #and now create rt auth3
    auth3 = create_rt_authorization_for_customer(customer)

    #now let's go peruse the auth pages and verify things look good
    log_in_as customer
    get rtauthorizations_path
    assert_response :success
    assert_template 'rtauthorizations/index'

if false
#for an explanation of this commented out block, see the wordy comments in rtauthorizationscontroller#index above this line of code:
#@all_auths = @rtauthorizations
#this if false'd out block would work save for that hack hack
    authorizations = assigns(:authorizations)
    assert authorizations
    assert authorizations.any?
    assert_equal 1, authorizations.count
    assert_equal auth1, authorizations.first
end

    rtauths = assigns(:rtauthorizations)
    assert rtauths
    assert rtauths.any?
    assert_equal 2, rtauths.count
    assert_equal auth2, rtauths.first
    assert_equal auth3, rtauths[1]

    #now let's examine auth1 and verify data looks good
    get rtauthorization_path(auth1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    #there should be no subscriptions
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert_not subscriptions.any?
    #there should be one tote item and it should equal ti1
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 1, tote_items.count
    tote_item = tote_items.first
    assert_equal ti1, tote_item

    #now let's examine auth2 and verify data looks good
    get rtauthorization_path(auth2, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    #there should be one subscription
    subscriptions = assigns(:subscriptions)
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    #there should be one tote item and it should equal ti2
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 2, tote_items.count
    tote_item = tote_items.last
    assert_equal ti2, tote_item
    tote_item = tote_items.first
    assert_equal sxti1, tote_item
    #now lets examine auth3 show
    get rtauthorization_path(auth3, rta: 1)
    assert_response :success
    assert_template 'rtauthorizations/show'
    subscriptions = assigns(:subscriptions)
    #there should be one subscription and it should equal sx2
    assert subscriptions
    assert subscriptions.any?
    assert_equal 1, subscriptions.count
    assert_equal sx2, subscriptions.first
    #there should be one tote item and it should equal ti3
    tote_items = assigns(:tote_items)
    assert tote_items
    assert tote_items.any?
    assert_equal 2, tote_items.count
    tote_item = tote_items.last
    assert_equal ti3, tote_item
    assert_equal sxti2, tote_items.first    

  end

  test "all items in the series should point to the proper authorization 00" do
    #many auths throughout a subscription's lifetime. all items in the series should point to the proper authorization
    #sx gets auth'd, one item gets delivered, a different item gets auth'd. then another item in the sx series gets delivered. going to the tote item history should show link
    #to first authorization
    nuke_all_postings
    friday_next_week = get_next_wday_after(wday = 5, days_from_now = 7)
    posting1 = create_posting(farmer = nil, price = nil, product = Product.create(name: "Product1"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting2 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product2"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    posting3 = create_posting(posting1.user, price = nil, product = Product.create(name: "Product3"), unit = nil, delivery_date = friday_next_week, order_cutoff = nil, units_per_case = nil, frequency = 1)
    
    customer = create_new_customer

    #create first one time item
    ti1 = create_tote_item(customer, posting1, quantity = 1, frequency = 1, roll_until_filled = false)
    sx1 = ti1.subscription
    assert sx1
    assert sx1.valid?

    #make auth1
    auth1 = create_rt_authorization_for_customer(customer)
    assert_equal flash[:success], "Checkout successful"
    assert auth1.valid?

    #add 2nd product to tote
    ti1_posting2 = create_tote_item(customer, posting2, quantity = 1, frequency = nil, roll_until_filled = false)
    #make auth2
    auth2 = create_rt_authorization_for_customer(customer)

    #1st order cutoff
    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks
    #1st delivery
    fully_fill_creditor_order(posting1.creditor_order)
    assert ti1.reload.state?(:FILLED)
    assert ti1_posting2.reload.state?(:FILLED)

    #2nd order cutoff
    current_posting = sx1.reload.current_posting
    travel_to current_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    #2nd delivery
    fully_fill_creditor_order(current_posting.creditor_order)

    #now user goes to their history page
    log_in_as customer
    get tote_items_path(history: true)
    assert_response :success
    assert_template 'tote_items/history'
    tote_items = assigns(:tote_items)
    assert_equal 3, tote_items.count
    assert_select "div.caption a[href=?]", rtauthorization_path(auth1, rta: 1), {text: "View authorization", count: 2}   
    assert_select "div.caption a[href=?]", rtauthorization_path(auth2, rta: 1), {text: "View authorization", count: 1}

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