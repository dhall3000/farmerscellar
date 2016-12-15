require 'test_helper'
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
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #the reason for '4' is because there's elements for big and small screen and each of them have an expansion row containing a !
    assert_select '.glyphicon-exclamation-sign', {count: 4}
    #help text in the expansion row should exist
    assert_select 'li div p span.wont-fully-ship', {count: 2, text: "Currently this item will not ship"}        
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_bob.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal 7, additional_units_required_to_fill_my_case
    assert biggest_order_minimum_producer_net_outstanding > 100

    #we want to not tell bob that his order will only partially fill
    assert_select 'p span', {count: 1, text: "Currently this item will not ship"}
    assert_select 'p span', {count: 0, text: "Currently this item will only partially ship"}
    assert_select 'li ul li', {count: 0, text: "Currently only 10 of the 11 units ordered are set to ship"}
    #there is an OM deficiency in this case but let's not confuse the matter...let's just tell him about the case issues
    #once he solves that we can inform him about the OM problem
    assert_select 'li ul li a', {count: 0, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 1, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 0, text: "Other customer orders may increase total ordered amount above the minimum, causing your order to ship."}
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may fill this case, causing your order to ship."}    

    #sam should see an exclamation in his tote
    log_in_as(get_sam)
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #the reason for '4' is because there's elements for big and small screen and each of them have an expansion row containing a !
    assert_select '.glyphicon-exclamation-sign', {count: 4}
    #help text in the expansion row should exist
    assert_select 'li div p span.wont-fully-ship', {count: 2, text: "Currently this item will not ship"}        
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_sam.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal 7, additional_units_required_to_fill_my_case
    assert biggest_order_minimum_producer_net_outstanding > 100

    #we want to not tell sam that his order will only partially fill
    assert_select 'p span', {count: 1, text: "Currently this item will not ship"}
    assert_select 'p span', {count: 0, text: "Currently this item will only partially ship"}    
    #there is an OM deficiency in this case but let's not confuse the matter...let's just tell him about the case issues
    #once he solves that we can inform him about the OM problem
    assert_select 'li ul li a', {count: 0, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 1, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 0, text: "Other customer orders may increase total ordered amount above the minimum, causing your order to ship."}
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may fill this case, causing your order to ship."}    

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
    assert_equal 0, posting.biggest_order_minimum_producer_net_outstanding
    
    #bob should see an exclamation in his tote
    log_in_as(get_bob)
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #the reason for '4' is because there's elements for big and small screen and each of them have an expansion row containing a !
    assert_select '.glyphicon-exclamation-sign', {count: 4}
    #help text in the expansion row should exist
    assert_select 'li div p span', {count: 2, text: "Currently this item will only partially ship"}
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_bob.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal 7, additional_units_required_to_fill_my_case
    assert_equal 0, biggest_order_minimum_producer_net_outstanding

    #we want to tell bob that his order will only partially fill
    assert_select 'p span', {count: 1, text: "Currently this item will only partially ship"}
    assert_select 'li ul li', {count: 1, text: "Currently only 10 of the 11 units ordered are set to ship"}
    #we want to make sure to not tell him there's an OM problem
    assert_select 'li ul li a', {count: 0, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 1, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may fill this case, causing your order to fully ship."}

    #now, what is the experience like from sam's perspective?
    log_in_as(get_sam)
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #the reason for '4' is because there's elements for big and small screen and each of them have an expansion row containing a !
    assert_select '.glyphicon-exclamation-sign', {count: 4}
    #help text in the expansion row should exist
    assert_select 'li div p span', {count: 2, text: "Currently this item will not ship"}
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_sam.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal 7, additional_units_required_to_fill_my_case
    assert_equal 0, biggest_order_minimum_producer_net_outstanding

    #we want to tell sam that his order will not ship because the case is not full
    assert_select 'p span', {count: 1, text: "Currently this item will not ship"}
    #we want to make sure the 'partially filled' message is not present
    assert_no_match "units ordered are set to ship", response.body
    #we want to make sure to not tell him there's an OM problem
    assert_select 'li ul li a', {count: 0, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 1, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may fill this case, causing your order to ship."}

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

    get_bobs_orders_page
    assert_select 'div#orderTotal', {count: 1, text: "Total: $60.00" }

    #there should be no problems indicated to the user
    assert_select '.glyphicon-exclamation-sign', {count: 0}

    #user shouldn't be able to get to the pout but if they did it should redirect them to the shopping pages
    post tote_items_pout_path, params: {id: ti_bob.id}
    assert_response :redirect
    assert_redirected_to postings_path
    
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
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #total amount should be properly displayed    
    assert_select 'div#orderTotal', {count: 1, text: "Total: #{number_to_currency(ti_bob.quantity * ti_bob.posting.price)}" }

    #icons in the tote should indicate a problem
    assert_select '.glyphicon-exclamation-sign', {count: 4}

    #help text in the expansion row should exist
    assert_select 'li div p span', {count: 2, text: "Currently this item will not ship"}    
    
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_bob.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal 0, additional_units_required_to_fill_my_case
    assert biggest_order_minimum_producer_net_outstanding > 0    
    assert biggest_order_minimum_producer_net_outstanding < posting.user.order_minimum_producer_net
    assert_equal posting.biggest_order_minimum_producer_net_outstanding, biggest_order_minimum_producer_net_outstanding

    #there's a problem with OM but not with case so we don't want to show any text related to case technology
    assert_select 'p span', {count: 1, text: "Currently this item will not ship"}
    assert_select 'p span', {count: 0, text: "Currently this item will only partially ship"}    
    assert_select 'li ul li a', {count: 1, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 0, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may increase total ordered amount above the minimum, causing your order to ship."}
    assert_select 'li ul li div p', {count: 0, text: "Other customer orders may fill this case, causing your order to ship."}    

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
    assert_equal ti_bob.posting.units_per_case - total_quantity_ordered, ti_bob.additional_units_required_to_fill_my_case
    #the OM for bob's item's posting should be fully satisfied theoretically because $60 was ordered and OM = $50.
    #however, since the 1st case wasn't filled the actual quantity set to be ordered from producer is 0 units
    #so the fully OM is outstanding
    order_min = ti_bob.posting.user.order_minimum_producer_net
    assert_equal order_min, ti_bob.posting.biggest_order_minimum_producer_net_outstanding

    #bob's user experience should reflect that the case his item is in isn't yet filled. it should say nothing about the unmet OM.
    log_in_as(get_bob)
    get tote_items_path, params: {orders: true}
    assert_response :success
    assert_template 'tote_items/orders'

    #total amount should be properly displayed    
    assert_select 'div#orderTotal', {count: 1, text: "Total: #{number_to_currency(ti_bob.quantity * ti_bob.posting.price)}" }

    #icons in the tote should indicate a problem
    assert_select '.glyphicon-exclamation-sign', {count: 4}

    #help text in the expansion row should exist
    assert_select 'li div p span', {count: 2, text: "Currently this item will not ship"}    
    
    #there should be a 'More info' button to get user to the pout page
    assert_select 'input[type=?][value=?]', "submit", "More info", 2#, {count: 2, text: "More info"}

    #user clicks 'More info' button
    post tote_items_pout_path, params: {id: ti_bob.id}
    assert_response :success
    assert_template 'tote_items/pout'

    additional_units_required_to_fill_my_case = assigns(:additional_units_required_to_fill_my_case)
    biggest_order_minimum_producer_net_outstanding = assigns(:biggest_order_minimum_producer_net_outstanding)

    assert_equal ti_bob.posting.units_per_case - total_quantity_ordered, additional_units_required_to_fill_my_case
    assert_equal 50, biggest_order_minimum_producer_net_outstanding

    #since there's a problem with both case and OM we only want to display case issues
    assert_select 'p span', {count: 1, text: "Currently this item will not ship"}    
    #there should not be a link telling user about unmet group OM
    assert_select 'li ul li a', {count: 0, text: "Group Order Minimum"}
    assert_select 'li ul li', {count: 1, text: "Reason: the case that your order will ship in is not yet full"}
    assert_select 'li h5', count: 1, text: "Resolution"
    assert_select 'li ul li div p', {count: 1, text: "Other customer orders may fill this case, causing your order to ship."}

  end

end