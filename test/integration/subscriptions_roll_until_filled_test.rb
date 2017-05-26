require 'integration_helper'

class SubscriptionsRollUntilFilledTest < IntegrationHelper

  test "user should be charged the amount they authorized if we raise the price before they get filled" do

    nuke_all_postings
    posting1 = create_posting(producer = nil, price = 1, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 10)
    bob = create_new_customer("bob", "bob@b.com")
    sam = create_new_customer("sam", "sam@b.com")

    #bob auths one which isn't enough to hit the OM so it won't fill
    ti_bob = create_tote_item(bob, posting1, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(bob)

    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    posting2 = posting1.reload.posting_recurrence.current_posting
    assert_not_equal posting1, posting2

    #log in as farmer
    log_in_as posting2.user
    #increase the price
    patch posting_path(posting2), params: { posting: {price: 1.5, posting_recurrence: {on: 1}} }
    assert_response :redirect
    assert_redirected_to user_path(posting2.user)
    follow_redirect!
    assert_not flash.empty?
    assert_equal "Posting updated!", flash[:success]
    assert_equal 1.5, posting2.reload.price

    ti_sam = create_tote_item(sam, posting2, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(sam)

    assert_equal 1.5, ti_sam.price
    assert_equal 1.0, ti_bob.price

    #order min still isn't met so let's fast forward to posting2 oc
    travel_to posting2.order_cutoff
    RakeHelper.do_hourly_tasks

    ti = ti_bob.subscription.current_tote_item
    debugger
    xxx = 1


  end

  test "should show just once option when no constraints present" do

    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 0)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = nil)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {posting_id: posting.id, quantity: 6}
    assert_response :success
    assert_template 'tote_items/how_often'

    #there are no constraints so both options should be present
    #search for the comments and code at this string 'business bootstrapping code'. for the reasons in that comment i decided to 100% yank the vanilla 'Just Once'
    #option until our sales are huge
    #assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 1
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1

  end

  test "should not show just once option when order minimum unmet" do

    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 50)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {quantity: 2, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'

    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1

  end

  test "should show just once option when order minimum met" do

    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 50)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {quantity: 6, posting_id: posting.id}
    assert_response :success
    assert_template 'tote_items/how_often'
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1
    post tote_items_path, params: {quantity: 6, posting_id: posting.id, frequency: 0}

    create_rt_authorization_for_customer(bob)

    #ok, now the vanilla Just Once option should show up since OM has now been met
    post tote_items_path, params: {quantity: 6, posting_id: posting.id}    
    assert_response :success
    assert_template 'tote_items/how_often'

    #search for the comments and code at this string 'business bootstrapping code'. for the reasons in that comment i decided to 100% yank the vanilla 'Just Once'
    #option until our sales are huge
    #assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 1
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1

  end

  test "should not show just once option when case constraints unmet" do
    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 0)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = 10, frequency = 1, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {quantity: 2, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'

    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1

  end

  test "should show just once option once case constraints met" do
    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 0)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = 10, frequency = 1, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {quantity: 12, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1
    post tote_items_path, params: {quantity: 12, posting_id: posting.id, frequency: 0}

    create_rt_authorization_for_customer(bob)

    #now vanilla just once option should be shown since the 1st case is full
    post tote_items_path, params: {quantity: 12, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'

    #search for the comments and code at this string 'business bootstrapping code'. for the reasons in that comment i decided to 100% yank the vanilla 'Just Once'
    #option until our sales are huge
    #assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 1
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1

  end

  test "should not show just once option when order minimum and case constraints unmet" do
    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.

    nuke_all_postings
    nuke_all_users

    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 50)
    posting = create_posting(producer, price = 10, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = 10, frequency = 1, order_minimum_producer_net = 0)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    assert is_logged_in?

    post tote_items_path, params: {quantity: 2, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template "tote_items/how_often"
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1
    post tote_items_path, params: {quantity: 2, posting_id: posting.id, frequency: 0}
    
    #now make case and OM constraints met and vanilla just once option should show up
    post tote_items_path, params: {quantity: 12, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 0
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1
    post tote_items_path, params: {quantity: 12, posting_id: posting.id, frequency: 0}

    create_rt_authorization_for_customer(bob)

    post tote_items_path, params: {quantity: 1, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    assert_response :success
    assert_template 'tote_items/how_often'

    #search for the comments and code at this string 'business bootstrapping code'. for the reasons in that comment i decided to 100% yank the vanilla 'Just Once'
    #option until our sales are huge
    #assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 1
    assert_select 'div div div form input[type=?][value=?]', "submit", "Just once (roll until filled)", 1    

  end

  test "should cancel authorized order when user cancels between first postings cutoff and delivery order does not fill" do

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence    
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 2, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)
    assert_equal 1, sam.reload.tote_items.count

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)
    assert ti_bob.reload.state?(:AUTHORIZED)
    assert ti_sam.reload.state?(:AUTHORIZED)

    #move to posting 1 order cutoff
    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    #generate producer order and 'next' tote items
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count
    sam.reload
    first_ti = sam.tote_items.first
    second_ti = sam.tote_items.last
    assert first_ti.state?(:NOTFILLED)
    assert second_ti.state?(:AUTHORIZED)

    #move to a day between first posting's order cutoff and delivery date
    travel 1.day

    #attempt to cancel sam's order    
    log_in_as(sam)
    delete tote_item_path(id: second_ti.id)
    assert_response :redirect
    assert_redirected_to tote_items_path(orders: second_ti.posting.delivery_date.to_s)
    follow_redirect!
    #verify danger flash message
    assert_equal "#{second_ti.posting.product.name} canceled", flash[:success]
    #verify one item REMOVED
    assert second_ti.reload.state?(:REMOVED)
    #verify subscription object off
    assert_not first_ti.subscription.on    
    #verify no more items get generated
    travel_to second_ti.posting.order_cutoff    
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count

    travel_back

  end

  test "should cancel authorized order when user cancels between first postings cutoff and delivery order fills" do
    #when user has auth'd RTF order between order cutoff and delivery the Orders page will show two tote items; one
    #for the upcoming delivery and another for the delivery after that. the user who attempts to cancel their RTF order
    #at this time might do so by clicking 'remove' on either of the two. regardless which one the user attempts we need
    #to make the behavior be the same: the latter gets REMOVED and the former generates a flash danger message and
    #remains in place. the subscription object always needs to get turned off as well.
    #here user will make an attempt to nuke the COMMITTED tote item

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence    
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 25, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)
    assert_equal 1, sam.reload.tote_items.count

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)
    assert ti_bob.reload.state?(:AUTHORIZED)
    assert ti_sam.reload.state?(:AUTHORIZED)

    #move to posting 1 order cutoff
    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    #generate producer order and 'next' tote items
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count
    assert sam.tote_items.last.state?(:AUTHORIZED)

    #move to a day between first posting's order cutoff and delivery date
    travel 1.day

    #attempt to cancel sam's order
    assert ti_sam.reload.state?(:COMMITTED)
    log_in_as(sam)
    delete tote_item_path(id: ti_sam.id)
    assert_response :redirect
    assert_redirected_to tote_items_path(orders: ti_sam.posting.delivery_date.to_s)
    #verify danger flash message
    follow_redirect!
    assert_equal "Order not canceled. Order Cutoff was #{ti_sam.posting.order_cutoff.strftime("%a %b %e at %l:%M %p")}. Please see 'Order Cancellation' on the 'How Things Works' page for more details.", flash[:danger]
    #verify one item COMMITTED
    assert ti_sam.reload.state?(:COMMITTED)
    #verify one item REMOVED
    assert sam.reload.tote_items.last.state?(:REMOVED)
    #verify subscription object off
    assert_not ti_sam.subscription.on
    #verify one item gets filled
    travel_to ti_sam.posting.delivery_date + 12.hours
    fill_posting(first_posting, first_posting.total_quantity_authorized_or_committed)
    assert ti_sam.reload.state?(:FILLED)
    assert ti_sam.fully_filled?
    assert ti_sam.quantity > 0
    #verify delivery notification gets sent
    ActionMailer::Base.deliveries.clear
    do_delivery
    assert_equal 2, ActionMailer::Base.deliveries.count

    mail_one = ActionMailer::Base.deliveries.first
    mail_two = ActionMailer::Base.deliveries.last

    if mail_one.to[0] == ti_sam.user.email
      verify_proper_delivery_notification_email(mail_one, ti_sam.reload)
    else
      verify_proper_delivery_notification_email(mail_two, ti_sam.reload)
    end
    
    #verify no more items get generated
    travel_to first_posting.posting_recurrence.current_posting.order_cutoff    
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count

    travel_back

  end

  test "should cancel authorized order when user cancels between first postings cutoff and delivery order fills 2" do
    #when user has auth'd RTF order between order cutoff and delivery the Orders page will show two tote items; one
    #for the upcoming delivery and another for the delivery after that. the user who attempts to cancel their RTF order
    #at this time might do so by clicking 'remove' on either of the two. regardless which one the user attempts we need
    #to make the behavior be the same: the latter gets REMOVED and the former generates a flash danger message and
    #remains in place. the subscription object always needs to get turned off as well.
    #here user will make an attempt to nuke the AUTHORIZED tote item
    #here's how it should behave. user nukes this item and gets the usual treatment. a success flash saying item canceled.
    #but in the background it also turns off the RTF subscription object. they also do not get any warning that they
    #can't cancel the COMMITTED item. we redirect them back to the orders page after they nuke the AUTH'd item and assume
    #they'll see the COMMITTED remains. this is where they'll probably try to nuke the COMMITTED item and then they'll see
    #the informative flash that tells them they can't do that.

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 25, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)
    assert_equal 1, sam.reload.tote_items.count

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)
    assert ti_bob.reload.state?(:AUTHORIZED)
    assert ti_sam.reload.state?(:AUTHORIZED)

    #move to posting 1 order cutoff
    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    #generate producer order and 'next' tote items
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count
    assert sam.tote_items.last.state?(:AUTHORIZED)

    #move to a day between first posting's order cutoff and delivery date
    travel 1.day

    #attempt to cancel sam's order
    assert ti_sam.reload.state?(:COMMITTED)
    log_in_as(sam)
    get tote_items_path params: {orders: ti_sam.posting.delivery_date.to_s}
    assert_response :success
    assert_template 'tote_items/orders'
    #make sure there's not a 'nuke item' link
    assert_select 'a.black.glyphicon-remove', 0
    #make sure there is a faux 'nuke item' link
    assert_select 'span.lightgray.glyphicon-remove', 1
    assert ti_sam.id != sam.reload.tote_items.last.id
    second_ti = sam.reload.tote_items.last
    delete tote_item_path(id: second_ti.id)
    assert_response :redirect
    assert_redirected_to tote_items_path(orders: second_ti.posting.delivery_date.to_s)
    follow_redirect!
    assert_template 'tote_items/orders'
    #verify danger flash message
    assert_equal "#{second_ti.posting.product.name} canceled", flash[:success]
    #verify one item COMMITTED
    assert ti_sam.reload.state?(:COMMITTED)
    #verify one item REMOVED
    assert sam.reload.tote_items.last.state?(:REMOVED)
    #verify subscription object off
    assert_not ti_sam.subscription.on
    #verify one item gets filled
    travel_to ti_sam.posting.delivery_date + 12.hours
    fill_posting(first_posting, first_posting.total_quantity_authorized_or_committed)
    assert ti_sam.reload.state?(:FILLED)
    assert ti_sam.fully_filled?
    assert ti_sam.quantity > 0
    #verify delivery notification gets sent
    ActionMailer::Base.deliveries.clear
    do_delivery
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    mail_one = ActionMailer::Base.deliveries.first
    mail_two = ActionMailer::Base.deliveries.last

    if mail_one.to[0] == ti_sam.user.email
      verify_proper_delivery_notification_email(mail_one, ti_sam.reload)
    else
      verify_proper_delivery_notification_email(mail_two, ti_sam.reload)
    end
    
    #verify no more items get generated
    travel_to first_posting.posting_recurrence.current_posting.order_cutoff    
    RakeHelper.do_hourly_tasks
    assert_equal 2, sam.reload.tote_items.count

    travel_back

  end

  test "should cancel authorized order when user cancels before first cutoff" do

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence    
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 2, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)

    assert ti_bob.reload.state?(:AUTHORIZED)
    assert ti_sam.reload.state?(:AUTHORIZED)

    #cancel sam's order
    log_in_as(sam)
    delete tote_item_path(id: ti_sam.id)
    assert_response :redirect
    #verify tote item REMOVED
    assert ti_sam.reload.state?(:REMOVED)
    #verify subscription object off
    assert_not ti_sam.subscription.on        
    #verify no more items get generated
    assert_equal 1, sam.tote_items.count
    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    assert_equal 1, sam.reload.tote_items.count

    travel_back

  end

  test "should cancel added order when user cancels before first cutoff" do

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence    
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 2, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)

    #cancel sam's order
    log_in_as(sam)
    delete tote_item_path(id: ti_sam.id)
    assert_response :redirect
    #verify tote item REMOVED
    assert ti_sam.reload.state?(:REMOVED)
    #verify subscription object off
    assert_not ti_sam.subscription.on        
    #verify no more items get generated
    assert_equal 1, sam.tote_items.count
    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    assert_equal 1, sam.reload.tote_items.count

    travel_back

  end

  test "skip date action should not act on rtf subscriptions" do

    nuke_all_postings
    bob = create_user("bob", "bob@b.com")
    
    #2 create rtf subscription
    pr_celery_rtf = create_posting(farmer = nil, price = 2.29, product = products(:celery), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence
    celery_subscription = create_tote_item(bob, pr_celery_rtf.current_posting, quantity = 3, frequency = 0, roll_until_filled = true).subscription
    assert celery_subscription
    assert celery_subscription.kind?(:ROLLUNTILFILLED)

    log_in_as(bob)
    #4 verify show does not display celery RTF subscription
    get subscription_path(celery_subscription)
    assert :redirect
    assert_redirected_to subscriptions_path
    #5 verify edit does not display celery RTF subscription
    get edit_subscription_path(celery_subscription)
    assert :redirect
    assert_redirected_to subscriptions_path

    immediate_next_delivery_date = ToteItem.where(user_id: bob.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, celery_subscription

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #specify skip INDD
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {celery_subscription.id.to_s => [indd.posting.delivery_date.to_s]},
      subscription_ids: [celery_subscription.id.to_s],
      end_date: (indd.posting.delivery_date + 7.days).to_s
    }

    #verify INDD did not get REMOVED (i.e. skipped)
    assert_not indd.reload.state?(:REMOVED)
    
  end

  test "neither show nor edit should display rtf subscriptions" do

    nuke_all_postings
    bob = create_user("bob", "bob@b.com")
    #1 create regular subscription
    pr_apples = create_posting(farmer = nil, price = 1, product = products(:apples), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence

    assert pr_apples.valid?
    apples_subscription = create_tote_item(bob, pr_apples.current_posting, quantity = 2, frequency = 1).subscription
    assert apples_subscription
    
    #2 create rtf subscription
    pr_celery_rtf = create_posting(farmer = pr_apples.current_posting.user, price = 2.29, product = products(:celery), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence

    celery_subscription = create_tote_item(bob, pr_celery_rtf.current_posting, quantity = 3, frequency = 0, roll_until_filled = true).subscription
    assert celery_subscription
    assert celery_subscription.kind?(:ROLLUNTILFILLED)

    log_in_as(bob)
    #3 verify displays apples subscription
    get subscription_path(apples_subscription)
    assert :success
    assert_template 'subscriptions/show'
    assert_select 'p', "john Farms Fuji Apples"      
    #4 verify show does not display celery RTF subscription
    get subscription_path(celery_subscription)
    assert :redirect
    assert_redirected_to subscriptions_path
    #5 verify edit does not display celery RTF subscription
    get edit_subscription_path(celery_subscription)
    assert :redirect
    assert_redirected_to subscriptions_path

  end

  test "index should not display rtf subscriptions" do

    nuke_all_postings
    bob = create_user("bob", "bob@b.com")
    #1 create regular subscription    
    pr_apples = create_posting(farmer = nil, price = 1, product = products(:apples), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence
    assert pr_apples.valid?
    ti = create_tote_item(bob, pr_apples.current_posting, quantity = 2, frequency = 1)
    assert ti.subscription
    
    #2 create rtf subscription
    pr_celery_rtf = create_posting(farmer = pr_apples.current_posting.user, price = 2.29, product = products(:celery), unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence
    ti = create_tote_item(bob, pr_celery_rtf.current_posting, quantity = 3, frequency = 0, roll_until_filled = true)
    assert ti.subscription
    assert ti.subscription.kind?(:ROLLUNTILFILLED)
    #3 view subscriptions index
    log_in_as(bob)
    create_rt_authorization_for_customer(bob)
    get subscriptions_path
    assert_template 'subscriptions/index'    
    #4 verify normal subscription is visible
    assert_select 'a', "john Farms Fuji Apples"
    #5 verify rtf sub is not displayed
    assert_select 'a', {text: "john Farms Celery", count: 0}    

  end

  test "subscription should regenerate each recurrence until order fills once then cancel subscription" do

    #1producer has an order minimum
    #2bob places just once order
    #3sam places a just once RUF order
    #4however, the sum does not meet the order minimum
    #5so the order is never submitted to the producer
    #6the next cycle bob places a subscription order that bumps the sum up over the OM
    #7both bob and sam should get filled on delivery #2
    #8for delivery #3 sam should not get filled
    #9sam's order should be canceled
    #10bob should continue to get filled.

    nuke_all_postings

    pr = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1).posting_recurrence
    pr.current_posting.update(price: 1)
    pr.current_posting.user.update(order_minimum_producer_net: 20)

    bob = create_user("bob", "bob@b.com")
    sam = create_user("sam", "sam@s.com")

    ti_bob = create_tote_item(bob, pr.current_posting, quantity = 2, frequency = 0)
    assert ti_bob.valid?
    assert ti_bob.state?(:ADDED)

    ti_sam = create_tote_item(sam, pr.current_posting, quantity = 2, frequency = 0, roll_until_filled = true)
    assert ti_sam.valid?
    assert ti_sam.state?(:ADDED)

    create_rt_authorization_for_customer(bob)
    create_rt_authorization_for_customer(sam)

    first_posting = pr.current_posting
    travel_to first_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    #verify that order email did not get sent
    assert_equal 0, ActionMailer::Base.deliveries.count    
    assert first_posting.reload.state?(:CLOSED)

    #now verify that second posting has one item for sam and none for bob
    second_posting = pr.reload.current_posting
    assert second_posting.state?(:OPEN)
    assert_equal 1, second_posting.tote_items.count
    assert sam, second_posting.tote_items.first.state?(:AUTHORIZED)
    assert sam, second_posting.tote_items.first.user
    assert second_posting.tote_items.first.subscription
    assert second_posting.tote_items.first.subscription.kind?(:ROLLUNTILFILLED)

    #advance to first_posting delivery date and verify no delivery notifications were sent
    travel_to first_posting.delivery_date + 12.hours
    do_delivery
    assert_equal 0, ActionMailer::Base.deliveries.count

    #6
    ti_sam = sam.tote_items.last
    ti_bob = create_tote_item(bob, second_posting, quantity = 25, frequency = 1)
    create_rt_authorization_for_customer(bob)

    #7
    travel_to second_posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks
    #verify that order email did get sent
    assert_equal 1, ActionMailer::Base.deliveries.count    
    assert second_posting.reload.state?(:COMMITMENTZONE)
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.first, second_posting.user.get_creditor, second_posting, second_posting.total_quantity_authorized_or_committed, 1, 1)

    travel_to second_posting.delivery_date + 12.hours
    assert_equal 27, second_posting.total_quantity_authorized_or_committed
    fill_posting(second_posting, second_posting.total_quantity_authorized_or_committed)
    ActionMailer::Base.deliveries.clear
    do_delivery
    #two delivery notifications should have gone out
    assert_equal 2, ActionMailer::Base.deliveries.count

    mail_one = ActionMailer::Base.deliveries.first
    mail_two = ActionMailer::Base.deliveries.last

    if mail_one.to[0] == ti_bob.user.email
      verify_proper_delivery_notification_email(mail_one, ti_bob.reload)
      verify_proper_delivery_notification_email(mail_two, ti_sam.reload)
    else
      verify_proper_delivery_notification_email(mail_two, ti_bob.reload)
      verify_proper_delivery_notification_email(mail_one, ti_sam.reload)
    end

    #bob's last tote item should be authorized
    assert bob.tote_items.last.state?(:AUTHORIZED)
    assert_equal 3, bob.tote_items.count
    #from here on out sam should have 3 items
    assert_equal 3, sam.tote_items.count
    #sam's last tote item should be removed
    assert sam.tote_items.last.state?(:REMOVED), "state is #{sam.tote_items.last.state.to_s}"
    #sam's subscription should be off
    assert_not sam.tote_items.last.subscription.on

    third_posting = pr.current_posting
    assert_not_equal second_posting, third_posting
    assert third_posting.id > second_posting.id

    travel_to third_posting.order_cutoff
    RakeHelper.do_hourly_tasks

    #sam should still have the same number of tote items as the last check cause his subscription should have been turned off
    assert_equal 3, sam.reload.tote_items.count
    #bob, however, should have an additional ti
    assert_equal 4, bob.reload.tote_items.count
    assert bob.tote_items.last.state?(:AUTHORIZED)

    travel_back

  end

end