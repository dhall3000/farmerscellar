require 'integration_helper'

class PoutPageTest < IntegrationHelper

  test "should not say user item will partially fill if om still unmet" do
    #tote shows  ! icon. pout shows This item will not/partially ship  case not filled, this much remaining to fill case

    posting = producer_posting_user_setup
    posting.user.update(order_minimum_producer_net: 200)
    
    bob = get_bob
    sam = get_sam    

    #this will make it so that the OM is theoretically unmet and the 1st case is not yet full
    ti_bob = create_tote_item(bob, posting, quantity = 11, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 2, frequency = nil, roll_until_filled = nil)

    do_authorizations

    ti_bob = get_bob_ti
    ti_sam = get_sam_ti

    assert ti_bob.reload.state?(:AUTHORIZED)    
    assert ti_sam.reload.state?(:AUTHORIZED)

    #bob's item spans a case so he should get partially filled except that OM unmet so he should be told he'll
    #get partially filled
    assert_equal 7, ti_bob.additional_units_required_to_fill_my_case
    #OM should be unmet. only one case should be orderable at this point which is $100 retail but minus costs
    #the producer net orderable (inbound) should be  < 100. this means the amount outstanding should be > 100
    assert posting.biggest_order_minimum_producer_net_outstanding < 120
    assert posting.biggest_order_minimum_producer_net_outstanding > 100

    #bob should see an exclamation in his tote
    log_in_as(get_bob)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.gentle-flash.glyphicon-exclamation-sign'

    #now user drills in on a certain day
    get tote_items_path(orders: ti_bob.posting.delivery_date.to_s)    
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'div.thumbnail span.gentle-flash.glyphicon-exclamation-sign'

    #we want to not tell bob that his order will only partially fill
    assert_select 'div.alert.alert-danger', {count: 0, text: "Item will partially fill. 10 of your 11 units ordered will ship."}
    assert_select 'div.alert.alert-danger', {count: 1, text: "Item won't ship. $108.50 Club Order Minimum shortfall."}

    #sam should see an exclamation in his tote
    log_in_as(get_sam)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'

    #now user drills in on a certain day
    get tote_items_path(orders: ti_sam.posting.delivery_date.to_s)
    assert_response :success
    assert_template 'tote_items/orders'

    additional_units_required_to_fill_my_case = ti_sam.reload.additional_units_required_to_fill_my_case
    biggest_order_minimum_producer_net_outstanding = ti_sam.posting.biggest_order_minimum_producer_net_outstanding

    assert_equal 7, additional_units_required_to_fill_my_case
    assert biggest_order_minimum_producer_net_outstanding > 100

    #we want to not tell sam that his order will only partially fill
    assert_select 'div.alert.alert-danger', {count: 1, text: "Item won't ship. $108.50 Club Order Minimum shortfall."}

  end

  test "should show proper pout helps when order min met but user item wont ship cause case not full" do
    #tote shows  ! icon. pout shows This item will not/partially ship  case not filled, this much remaining to fill case

    posting = producer_posting_user_setup
    
    bob = get_bob
    sam = get_sam    

    #this will make it so that the OM is theoretically unmet and the 1st case is not yet full
    ti_bob = create_tote_item(bob, posting, quantity = 11, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 2, frequency = nil, roll_until_filled = nil)

    do_authorizations

    ti_bob = get_bob_ti
    ti_sam = get_sam_ti

    assert ti_bob.reload.state?(:AUTHORIZED)    
    assert ti_sam.reload.state?(:AUTHORIZED)

    #bob's item spans a case so he should get partially filled
    assert_equal 7, ti_bob.additional_units_required_to_fill_my_case
    #OM should be met
    assert_equal 0, posting.reload.biggest_order_minimum_producer_net_outstanding
    
    #bob should see an exclamation in his tote
    log_in_as(get_bob)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.gentle-flash.glyphicon-exclamation-sign'

    get tote_items_path, params: {orders: ti_bob.posting.delivery_date.to_s}
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'div.thumbnail span.gentle-flash.glyphicon-exclamation-sign'

    assert_select 'div.alert.alert-danger', {count: 1, text: "Item will partially fill. 10 of your 11 units ordered will ship."}
    assert_select 'div.alert.alert-danger', {count: 0, text: "Item won't ship. $108.50 Club Order Minimum shortfall."}

    #now, what is the experience like from sam's perspective?
    log_in_as(get_sam)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.gentle-flash.glyphicon-exclamation-sign'

    get tote_items_path, params: {orders: ti_bob.posting.delivery_date.to_s}
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'div.thumbnail span.gentle-flash.glyphicon-exclamation-sign'

    assert_select 'div.alert.alert-danger', {count: 1, text: "Case not full. Item won't ship. 7 more units needed to fill case."}

  end

  test "should show proper pout helps when case constraints met and order min met" do
    #tote shows no icon. pout shows no help text “all good”

    posting = producer_posting_user_setup
    
    bob = get_bob
    sam = get_sam    

    ti_bob = create_tote_item(bob, posting, quantity = 6, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 6, frequency = nil, roll_until_filled = nil)

    do_authorizations

    assert ti_bob.reload.state?(:AUTHORIZED)    
    assert ti_sam.reload.state?(:AUTHORIZED)

    #the case bob's item is in should be fully filled now
    assert_equal 0, ti_bob.additional_units_required_to_fill_my_case
    #the OM for bob's item's posting should be fully satisfied    
    assert_equal 0, ti_bob.posting.biggest_order_minimum_producer_net_outstanding

    log_in_as bob
    get tote_items_path(calendar: 1)
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.gentle-flash.glyphicon-exclamation-sign', 0

    get tote_items_path(orders: ti_bob.posting.delivery_date.to_s)
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'gentle-flash.glyphicon-exclamation-sign', 0
    assert_select 'strong', {count: 1, text: "Total $60.00"}
    
  end

  test "should show proper pout helps when case constraints unmet and order min met" do
    #tote shows  ! icon. pout shows This item will not/partially ship  case not filled, this much remaining to fill case

    posting = producer_posting_user_setup
    
    bob = get_bob
    sam = get_sam    

    #this will make it so that the OM is theoretically met but the 1st case is not yet full
    ti_bob = create_tote_item(bob, posting, quantity = 3, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 3, frequency = nil, roll_until_filled = nil)

    checks_when_both_case_and_om_unmet
    
  end

  test "should show proper pout helps when case constraints unmet and order min unmet" do
    #tote shows  ! icon. pout shows This item will not/partially ship  case not filled, this much remaining to fill case

    posting = producer_posting_user_setup
    
    bob = get_bob
    sam = get_sam    

    #this will make it so that the OM is theoretically unmet and the 1st case is not yet full
    ti_bob = create_tote_item(bob, posting, quantity = 2, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 2, frequency = nil, roll_until_filled = nil)

    checks_when_both_case_and_om_unmet
    
  end

  test "should show proper pout helps when case constraints met and order min unmet" do
    #tote shows  ! icon. pout shows This item won’t ship. OM unmet. $ much to go.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 120)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = 10, frequency = nil, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")
    sam = create_new_customer("sam", "sam@b.com")

    #this will make it so that the OM is unmet and the 1st case is full
    ti_bob = create_tote_item(bob, posting, quantity = 5, frequency = nil, roll_until_filled = nil)
    ti_sam = create_tote_item(sam, posting, quantity = 6, frequency = nil, roll_until_filled = nil)
    
    do_authorizations

    ti_bob = get_bob_ti
    ti_sam = get_sam_ti

    assert ti_bob.reload.state?(:AUTHORIZED)    
    assert ti_sam.reload.state?(:AUTHORIZED)

    #the case bob's item is in should be fully filled now
    assert_equal 0, ti_bob.additional_units_required_to_fill_my_case

    #the OM for bob's item's posting should not be fully satisfied theoretically
    assert posting.biggest_order_minimum_producer_net_outstanding > 0
    assert posting.biggest_order_minimum_producer_net_outstanding < posting.user.order_minimum_producer_net

    #bob's user experience should reflect that the case his item is in isn't yet filled. it should say nothing about the unmet OM.
    log_in_as(get_bob)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.gentle-flash.glyphicon-exclamation-sign'

    #now user drills in on a certain day
    get tote_items_path(orders: ti_bob.posting.delivery_date.to_s)    
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'div.thumbnail span.gentle-flash.glyphicon-exclamation-sign'

    #we want to not tell bob that his order will only partially fill
    assert_select 'div.alert.alert-danger', {count: 0, text: "Item will partially fill. 10 of your 11 units ordered will ship."}
    assert_select 'div.alert.alert-danger', {count: 1, text: "Item won't ship. $28.50 Club Order Minimum shortfall."}
    assert_select 'strong', {count: 1, text: "Total #{number_to_currency(ti_bob.quantity * ti_bob.posting.price)}" }

  end

  def producer_posting_user_setup

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 50)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = 10, frequency = nil, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")
    sam = create_new_customer("sam", "sam@b.com")

    return posting

  end

  def do_authorizations
    bob = get_bob
    sam = get_sam
    create_rt_authorization_for_customer(bob)    
    create_rt_authorization_for_customer(sam)
  end

  def get_bob
    bob = User.find_by(name: "bob")
    return bob
  end

  def get_sam
    sam = User.find_by(name: "sam")
    return sam
  end

  def get_bob_ti
    bob = get_bob
    ti = bob.tote_items.first
    return ti
  end

  def get_sam_ti
    sam = get_sam
    ti = sam.tote_items.first
    return ti
  end

  def get_bobs_orders_page
    #bob's user experience should reflect that there are no problems inhibiting shipping his order
    bob = get_bob
    log_in_as(bob)
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'
  end

  def checks_when_both_case_and_om_unmet
    do_authorizations

    ti_bob = get_bob_ti
    ti_sam = get_sam_ti

    assert ti_bob.reload.state?(:AUTHORIZED)    
    assert ti_sam.reload.state?(:AUTHORIZED)

    #the case bob's item is in should not be fully filled now
    assert ti_bob.additional_units_required_to_fill_my_case > 0
    total_quantity_ordered = ti_bob.quantity + ti_sam.quantity
    assert_equal ti_bob.posting.reload.units_per_case - total_quantity_ordered, ti_bob.additional_units_required_to_fill_my_case
    #the OM for bob's item's posting should be fully satisfied theoretically because $60 was ordered and OM = $50.
    #however, since the 1st case wasn't filled the actual quantity set to be ordered from producer is 0 units
    #so the full OM is outstanding. however, if we display to the user the full OM as outstanding this might be confusing because
    #although they've ordered product they see the outstanding om value unchanged.

    case_constraint_effective_om_outstanding = (ti_bob.posting.get_producer_net_case - ti_bob.posting.inbound_order_value_producer_net).round(2)
    theo_om_outstanding = ti_bob.posting.user.order_minimum_producer_net - ti_bob.posting.inbound_order_value_producer_net
    om_outstanding = [case_constraint_effective_om_outstanding, theo_om_outstanding].max
    assert_equal om_outstanding, ti_bob.posting.biggest_order_minimum_producer_net_outstanding    

    #bob's user experience should reflect that the case his item is in isn't yet filled. it should say nothing about the unmet OM.
    log_in_as(get_bob)
    get tote_items_path, params: {calendar: 1}
    assert_response :success
    assert_template 'tote_items/calendar'
    assert_select 'span.glyphicon-exclamation-sign', 1

    get tote_items_path, params: {orders: ti_bob.posting.delivery_date.to_s}
    assert_response :success
    assert_template 'tote_items/orders'
    assert_select 'span.glyphicon-exclamation-sign', 1

    #total amount should be properly displayed    
    assert_select 'strong', {count: 1, text: "Total #{number_to_currency(ti_bob.quantity * ti_bob.posting.price)}" }

    #since there's a problem with both case and OM we only want to display case issues
    assert_select 'div.alert.alert-danger', {count: 1, text: "Item won't ship. #{ActiveSupport::NumberHelper.number_to_currency(ti_bob.posting.biggest_order_minimum_producer_net_outstanding)} Club Order Minimum shortfall."}

  end

end