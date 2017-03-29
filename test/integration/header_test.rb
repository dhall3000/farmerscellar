require 'integration_helper'

class HeaderTest < IntegrationHelper

  test "number of active authorized subscriptions should be accurate" do
    bob = create_user
    #should report 0
    log_in_as bob
    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_template '/'

    #verify no subscriptions indicated
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    #add a non-recurring tote item
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil)
    ti = create_tote_item(bob, posting, quantity = 1)
    assert ti.valid?
    assert_response :redirect
    follow_redirect!
    #verify tote item shows in header
    assert_select 'span.glyphicon-shopping-cart ~ span.header-object-count', "1"
    #verify we do not see a subscription
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    #add sx to tote
    ti2 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should report 0
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    assert_equal 0, num_authorized_subscriptions_for(bob)
    #create authorization
    create_rt_authorization_for_customer(bob)
    get root_path
    #should report 1    
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"
    #add another subscription to tote
    ti3 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should still only be one authorized subscription
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"
    #now authorize and then verify there are two subscriptions
    create_rt_authorization_for_customer(bob)
    get root_path
    assert_equal 2, num_authorized_subscriptions_for(bob)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "2"
    #cancel first sx
    ti2.subscription.update(on: false)
    get root_path
    #should report 1
    assert_equal 1, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"    
    #cancel second sx
    ti3.subscription.update(on: false)
    get root_path
    #should report 0
    assert_equal 0, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""

    #now create a RTF order and verify this doesn't change the subscription count
    create_tote_item(bob, posting, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(bob)
    get root_path
    assert_equal 0, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""

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

    get root_path

    #header should not display a number since there are zero items ready for pickup
    assert_select 'span.glyphicon-ok ~ span.header-object-count', ""

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
    get root_path
    #header should now display there are 2 items ready for pickup
    assert_select 'span.glyphicon-ok ~ span.header-object-count', "2"
    do_pickup_for(users(:dropsite1), bob.reload, true)

    travel 61.minutes
    log_in_as bob
    get root_path
    #header should not display a number since there are zero items ready for pickup
    #since user just picked them up
    assert_select 'span.glyphicon-ok ~ span.header-object-count', ""

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
    get root_path

    #here's why there should be 3: the every other week item just got filled. so that should show. but a new tote item won't get generated for the 2-weeks-out posting
    #until the next order_cutoff hits. so for this series the calendar should only show 1 item. for the every-week subscription there should be one item for tomorrow's
    #delivery and another item for the delivery after that
    assert_select 'span.glyphicon-calendar ~ span.header-object-count', "3"

    travel_back
    
  end

end