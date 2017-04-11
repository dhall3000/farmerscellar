require 'integration_helper'

class OrdersTest < IntegrationHelper

  test "dev driver" do

    next_friday = get_next_wday_after(wday = 5, days_from_now = 7)

    nuke_all_users
    nuke_all_postings

    #friday posting
    posting1 = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = next_friday, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    #saturday posting
    posting2 = create_posting(posting1.user, price = nil, product = nil, unit = nil, delivery_date = next_friday + 1.day, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    #user has no orders
    bob = create_user
    #user has no orders for next friday
    log_in_as bob
    get tote_items_path(orders: next_friday.to_s)
    assert_response :success
    assert_template 'tote_items/orders'
    tote_items = assigns(:tote_items)
    assert_not tote_items.any?
    #user authorizes order for next friday
    ti1 = create_tote_item(bob, posting1, quantity = 1)
    ti2 = create_tote_item(bob, posting2, quantity = 1)
    create_rt_authorization_for_customer(bob)
    #now user goes to orders page for thursday, sees nothing
    get tote_items_path(orders: (next_friday - 1.day).to_s)
    assert_response :success
    assert_template 'tote_items/orders'
    tote_items = assigns(:tote_items)
    assert_not tote_items.any?
    #now user goes to orders page for friday, sees his order
    get tote_items_path(orders: (next_friday).to_s)
    assert_response :success
    assert_template 'tote_items/orders'
    tote_items = assigns(:tote_items)
    assert tote_items.any?
    assert_equal 1, tote_items.count
    assert_equal ti1, tote_items.first
    #now user goes to orders page for saturday, sees his order
    get tote_items_path(orders: (next_friday + 1.day).to_s)
    assert_response :success
    assert_template 'tote_items/orders'
    tote_items = assigns(:tote_items)
    assert tote_items.any?
    assert_equal 1, tote_items.count
    assert_equal ti2, tote_items.first

  end

end