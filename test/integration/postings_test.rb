require 'integration_helper'

class PostingsTest < IntegrationHelper

  def setup
    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)    
    @posting = postings(:postingf1apples)

    Product.all.each do |product|
      create_food_category_for_product_if_product_has_none(product)
    end

    create_food_category_for_product_if_product_has_none(@product)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.wday == STARTOFWEEK
      delivery_date = Time.zone.today + 4.days
    end

    @posting_case = Posting.new(units_per_case: 10, unit: @unit, product: @product, user: @farmer, description: "descrip", price: 1.25, live: true, order_cutoff: delivery_date - 2.days, delivery_date: delivery_date)
    @posting_case.save

  end

  test "should properly process upside down posting" do
    #description: an "upside down posting" is a posting where the producer_net_unit is > retail price. the first time this is being done is as a hack for glass bottles. the original scenario
    #on 2017-03-08 is we're getting Pure Eire raw milk in half gallon glass bottle from Pete's delivery for $4.50 + $2.50 bottle deposit. But, of course, we don't want to do the bottle
    #deposit / refund hassle with our customers so we're starting with an initial 'experimental' program to test a innovative idea. the idea is we're out a total of $7 / unit (plus paypal fees)
    #and we're charging customers $6.50 retail. if they bring the bottles back to us we make a profit. if they don't, we get killed. so we're keeping some metrics to see. but this test is to
    #verify it can work.

    nuke_all_postings

    price = 6.50
    producer_net_unit = 7.00
    posting = create_posting(farmer = nil, price, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit)
    assert posting.valid?

    bob = create_new_customer("bob", "bob@b.com")
    ti = create_tote_item(bob, posting, 1)
    assert ti.valid?
    assert ti.state?(:ADDED)

    create_one_time_authorization_for_customer(bob)
    assert ti.reload.state?(:AUTHORIZED)

    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks

    assert ti.reload.state?(:COMMITTED)

    travel_to posting.delivery_date + 12.hours
    fully_fill_creditor_order(posting.creditor_order)

    assert ti.reload.state?(:FILLED)

    travel_to posting.delivery_date + 22.hours

    assert_equal 0, Payment.count
    assert_equal 0, Purchase.count
    RakeHelper.do_hourly_tasks
    assert_equal 1, Payment.count
    assert_equal 1, Purchase.count

    assert_equal price, Purchase.first.gross_amount
    purchase_net = (price - 0.30 - (0.029 * price)).round(2)
    assert_equal purchase_net, Purchase.first.net_amount
    assert_equal producer_net_unit, Payment.first.amount

    expected = (price - (0.30 + 0.029 * price) - producer_net_unit).round(2)
    actual = (purchase_net - Payment.first.amount).round(2)

    assert_equal expected, actual

    travel_back

  end

  test "should properly divide postings into this next and future on first day of week" do

    assert STARTOFWEEK >= 0
    assert STARTOFWEEK <= 6

    nuke_all_postings

    while Time.zone.now.wday != STARTOFWEEK
      travel 1.day
    end

    assert_equal STARTOFWEEK, Time.zone.now.wday

    producer = create_producer("farmer john", "farmerjohn@jjohn.com")
    base_delivery_date = get_delivery_date(5)
    this_weeks_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date)
    next_weeks_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 7.days)
    future_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 14.days)

    get postings_path(food_category: FoodCategory.get_root_category.name)
    assert_response :success
    assert_template 'index'

    this_weeks_postings = assigns(:this_weeks_postings)
    assert_not this_weeks_postings.nil?
    assert_equal 1, this_weeks_postings.count
    assert_equal this_weeks_posting, this_weeks_postings.first

    next_weeks_postings = assigns(:next_weeks_postings)
    assert_not next_weeks_postings.nil?
    assert_equal 1, next_weeks_postings.count
    assert_equal next_weeks_posting, next_weeks_postings.first

    future_postings = assigns(:future_postings)
    assert_not future_postings.nil?
    assert_equal 1, future_postings.count
    assert_equal future_posting, future_postings.first

    travel_back

  end

  test "should properly divide postings into this next and future in middle of week" do

    assert STARTOFWEEK >= 0
    assert STARTOFWEEK <= 6

    nuke_all_postings

    while Time.zone.now.wday != STARTOFWEEK
      travel 1.day
    end

    assert_equal STARTOFWEEK, Time.zone.now.wday

    travel 1.day    

    producer = create_producer("farmer john", "farmerjohn@jjohn.com")
    base_delivery_date = get_delivery_date(5)
    this_weeks_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date)
    next_weeks_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 7.days)
    future_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 14.days)

    get postings_path(food_category: FoodCategory.get_root_category.name)
    assert_response :success
    assert_template 'index'

    this_weeks_postings = assigns(:this_weeks_postings)
    assert_not this_weeks_postings.nil?
    assert_equal 1, this_weeks_postings.count
    assert_equal this_weeks_posting, this_weeks_postings.first

    next_weeks_postings = assigns(:next_weeks_postings)
    assert_not next_weeks_postings.nil?
    assert_equal 1, next_weeks_postings.count
    assert_equal next_weeks_posting, next_weeks_postings.first

    future_postings = assigns(:future_postings)
    assert_not future_postings.nil?
    assert_equal 1, future_postings.count
    assert_equal future_posting, future_postings.first

    travel_back

  end

  test "should properly divide postings into this next and future on last day of week" do

    assert STARTOFWEEK >= 0
    assert STARTOFWEEK <= 6

    nuke_all_postings

    while Time.zone.now.wday != STARTOFWEEK
      travel 1.day
    end

    assert_equal STARTOFWEEK, Time.zone.now.wday    
    travel -1.day
    current_wday_should_be = STARTOFWEEK - 1
    if current_wday_should_be < 0
      current_wday_should_be += 7
    end
    assert_equal current_wday_should_be, Time.zone.now.wday

    producer = create_producer("farmer john", "farmerjohn@jjohn.com")
    base_delivery_date = get_delivery_date(5)
    first_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date)
    second_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 7.days)
    third_posting = create_posting(producer, price = nil, product = nil, unit = nil, base_delivery_date + 14.days)

    get postings_path(food_category: FoodCategory.get_root_category.name)
    assert_response :success
    assert_template 'index'

    this_weeks_postings = assigns(:this_weeks_postings)
    assert_not this_weeks_postings.nil?
    assert_equal 0, this_weeks_postings.count
    
    next_weeks_postings = assigns(:next_weeks_postings)
    assert_not next_weeks_postings.nil?
    assert_equal 1, next_weeks_postings.count
    assert_equal first_posting, next_weeks_postings.first

    future_postings = assigns(:future_postings)
    assert_not future_postings.nil?
    assert_equal 2, future_postings.count
    assert_equal second_posting, future_postings.first
    assert_equal third_posting, future_postings.last

    travel_back

  end

  test "dont send order email if unit count zero" do

    posting = create_standard_posting    
    assert posting.save
    assert_equal 0, posting.tote_items.count
    assert_equal Posting.states[:OPEN], posting.state

    travel_to posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel_back

  end

  test "should partially fill an item to complete a case then send correct order to creditor" do

    nuke_all_postings
    posting = create_standard_posting

    posting.units_per_case = 10
    assert posting.save
    assert_equal 0, posting.tote_items.count
    assert_equal Posting.states[:OPEN], posting.state

    c1 = users(:c1)
    ti = ToteItem.new(quantity: posting.units_per_case + 1, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user: c1)
    assert ti.save    
    assert_equal ToteItem.states[:ADDED], ti.reload.state
    ti.transition(:customer_authorized)
    assert_equal ToteItem.states[:AUTHORIZED], ti.reload.state

    travel_to posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks

    assert_equal 1, posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], posting.tote_items.first.state
    assert posting.reload.shippable?
    assert_equal posting.units_per_case + 1, posting.total_quantity_authorized_or_committed
    assert_equal posting.units_per_case, posting.inbound_num_units_ordered
    assert_equal 1, posting.inbound_num_cases_ordered

    #there should be a single email that went out; the order submission email to the producer
    assert_equal 1, ActionMailer::Base.deliveries.count
    #'verify' that the number '10' shows up which is that 10 units were ordered rather than the 11 that were committed
    
    subject = "Order for #{posting.delivery_date.strftime("%A, %B")} #{posting.delivery_date.day.ordinalize} delivery"

    assert_appropriate_email(ActionMailer::Base.deliveries[0], posting.user.get_business_interface.order_email, subject, "10")
    assert_appropriate_email(ActionMailer::Base.deliveries[0], posting.user.get_business_interface.order_email, subject, "1")

    #now once farmer delivers we want to verify we partially filled
    fill_report = fill_posting(posting, posting.inbound_num_units_ordered)

    posting.reload
    assert_equal 1, posting.tote_items.count
    ti = posting.tote_items.first
    ti.reload
    assert_equal ToteItem.states[:FILLED], ti.state
    assert ti.partially_filled?
    assert_not ti.zero_filled?
    assert_not ti.fully_filled?
    assert_equal posting.units_per_case + 1, ti.quantity
    assert_equal posting.units_per_case, ti.quantity_filled

    assert_equal posting.units_per_case, fill_report[:quantity_filled]
    assert_equal 1, fill_report[:quantity_not_filled]
    assert_equal 0, fill_report[:quantity_remaining]
    assert_equal 1, fill_report[:tote_items_filled].count
    assert_equal 1, fill_report[:partially_filled_tote_items].count    
    assert_equal 0, fill_report[:tote_items_not_filled].count
    assert_equal fill_report[:partially_filled_tote_items], fill_report[:tote_items_filled]

    travel_back

  end
  
  test "should not send order email if first case does not get filled" do
    nuke_all_postings
    posting = create_standard_posting

    posting.units_per_case = 10
    assert posting.save
    assert_equal 0, posting.tote_items.count
    assert_equal Posting.states[:OPEN], posting.state

    c1 = users(:c1)
    ti = ToteItem.new(quantity: posting.units_per_case - 1, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user: c1)
    assert ti.save    
    assert_equal ToteItem.states[:ADDED], ti.reload.state
    ti.transition(:customer_authorized)
    assert_equal ToteItem.states[:AUTHORIZED], ti.reload.state

    travel_to posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks
    posting.reload
    assert_equal 1, posting.tote_items.count
    assert_equal ToteItem.states[:NOTFILLED], posting.tote_items.first.state
    assert_not posting.shippable?
    assert_equal 0, posting.total_quantity_authorized_or_committed
    assert_equal 0, posting.inbound_num_units_ordered
    assert_equal 0, posting.inbound_num_cases_ordered

    #no emails whatsoever should get sent when a no-order posting rolls to the commitment zone
    assert_equal 0, ActionMailer::Base.deliveries.count
    #verify that no order email (or email of any kind) was sent to producer
    assert_not_email_to(posting.user.get_business_interface.order_email)    

    posting.reload
    assert_equal 1, posting.tote_items.count
    ti = posting.tote_items.first
    ti.reload
    assert_equal ToteItem.states[:NOTFILLED], ti.state
    assert_not ti.partially_filled?
    assert ti.zero_filled?
    assert_not ti.fully_filled?
    assert_equal posting.units_per_case - 1, ti.quantity
    assert_equal 0, ti.quantity_filled

    travel_back

  end

  test "will partially fill should really work" do

    #months after implementing I've become skeptical that ToteItem.will_partially_fill? really works
    #create a posting with units per case = 10
    #have 1st customer authorize for quantity 5
    #then have 2nd customer add for quantity 10
    #verify will partially fill reports true

    posting = create_standard_posting
    c1_quantity = 5
    c2_quantity = 10
    expected_additional_units_required_to_fill_my_case = 5
    
    #create an authorized tote item for c1 with quantity 5
    c1 = users(:c1)
    ti = ToteItem.new(quantity: c1_quantity, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert ti.save
    ti.transition(:customer_authorized)

    #log in as c2
    c2 = users(:c2)
    log_in_as(c2)
    #add tote item with quantity 10
    post tote_items_path, params: {quantity: c2_quantity, posting_id: posting.id}
    tote_item = assigns(:tote_item)

    #the case size is 10. c1 added 5 units and c2 just added 10. this is a total of 15 which means the 
    #additional_units_required_to_fill_my_case should be 5
    assert_equal expected_additional_units_required_to_fill_my_case, tote_item.additional_units_required_to_fill_my_case

    assert_response :redirect
    follow_redirect!
    assert_template 'postings/index'

    assert_not flash.empty?
    assert_equal "Tote item added", flash[:success]

    assert tote_item.will_partially_fill?
    assert_equal expected_additional_units_required_to_fill_my_case, tote_item.expected_fill_quantity

  end

  test "user 1 should see pout page then user 2 auths to fill case so user 1 should no longer see pout" do

    #c1 auths. then c2 adds above current case in to the next case. verify c1 now no longer sees pout page.
    posting = come_up_3_short
    c1 = users(:c1)
    c1_ti = c1.tote_items.order(:created_at).last
    assert_equal 7, c1_ti.additional_units_required_to_fill_my_case
    c2 = users(:c2)
    c2_ti = c2.tote_items.order(:created_at).last
    assert_equal ToteItem.states[:ADDED], c2_ti.state    
    c2_ti.transition(:customer_authorized)
    c2_ti.reload
    assert_equal ToteItem.states[:AUTHORIZED], c2_ti.state
    assert_equal 3, c1_ti.additional_units_required_to_fill_my_case

    #as of right now c1 has 3 auth'd and c2 has 4 auth'd for a total of 7. so if we log in as c1 and go to the tote
    #we should still see the red exclamation mark telling us the case isn't full yet, we're short 4
    log_in_as(c1)
    get tote_items_path(orders: true)
    assert_response :success
    assert_template 'tote_items/orders'    
    
    #log in as c2
    c2 = users(:c2)
    log_in_as(c2)
    #add tote item with quantity 4
    post tote_items_path, params: {quantity: 4, posting_id: posting.id}
    tote_item = assigns(:tote_item)

    #c2 should now be looking at the pout page
    assert_response :redirect
    follow_redirect!
    assert_template 'postings/index'
    assert_not flash.empty?
    assert_equal "Tote item added", flash[:success]

    #now authorize
    tote_item.transition(:customer_authorized)
    assert_equal ToteItem.states[:AUTHORIZED], tote_item.state

    #the case size is 10. c1 added 3 units and c2 just added 4. this is a total of 7 which means the 
    #additional_units_required_to_fill_my_case should be 3
    assert_equal 9, tote_item.additional_units_required_to_fill_my_case

    #now c1 shouldn't see the exclamation mark in the tote
    log_in_as(c1)
    get tote_items_path(orders: true)
    assert_response :success
    assert_template 'tote_items/orders'    
    assert_select "span.glyphicon-exclamation-sign", count: 0

  end

  test "c2 should fill case that c1 came up short on" do
    posting = come_up_3_short

    #at this point c1 has 3 authorized and c2 has 4 added for a total of 7
    #however, from c1's perspective only their own 3 count because c1 doesn't know
    #if/when c2 is going to authorize. so c1 should still see 7 remaining to fill the case
    c1 = users(:c1)
    c1_ti = c1.tote_items.order(:created_at).last
    assert_equal ToteItem.states[:AUTHORIZED], c1_ti.state
    assert_equal 7, c1_ti.additional_units_required_to_fill_my_case

    #c1 has 3 auth'd and c2 has 4 added for a total of 7 so there are still 3 remaining that need to be ordered
    c2 = users(:c2)
    c2_ti = c2.tote_items.order(:created_at).last
    assert_equal ToteItem.states[:ADDED], c2_ti.state
    assert_equal 3, c2_ti.additional_units_required_to_fill_my_case

    #so c1 saw "7 remaining" on the pout page so they add 7 more
    ti = ToteItem.new(quantity: 7, posting_id: posting.id, state: ToteItem.states[:AUTHORIZED], price: posting.price, user_id: c1.id)
    assert ti.save
    #so now c1 shouldn't see the pout page anymore
    assert_equal 0, ti.additional_units_required_to_fill_my_case

    #but now c2 got kicked in to the next case so they should see 6
    assert_equal 6, c2_ti.additional_units_required_to_fill_my_case

    #c1 adds some quantity
    #c1 sees pout page requiring 4 more units
    #c1 doesn't add anymore and doesn't authorize either
    #c2 adds 5 units
    #c1 now sees 9 units required
  end

  test "should get pout page the first add but not the second" do
    posting = come_up_3_short
    #user got sent to the pout page telling them they were three units short of a full case
    #so now they just added 3 more. it should not send them to pout page but back to shopping page
    post tote_items_path, params: {quantity: 3, posting_id: posting.id}
    tote_item = assigns(:tote_item)

    #the case size is 10. c1 just found out the case was 3 units shy so they added 3 more so
    #additional_units_required_to_fill_my_case should be 0
    assert_equal 0, tote_item.additional_units_required_to_fill_my_case

    assert_response :redirect
    follow_redirect!
    assert_template 'postings/index'

  end

  def come_up_3_short

    posting = create_standard_posting
    
    #create an authorized tote item for c1 with quantity 3
    c1 = users(:c1)
    ti = ToteItem.new(quantity: 3, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert ti.save
    ti.transition(:customer_authorized)

    #log in as c2
    c2 = users(:c2)
    log_in_as(c2)
    #add tote item with quantity 4
    post tote_items_path, params: {quantity: 4, posting_id: posting.id}
    tote_item = assigns(:tote_item)

    #the case size is 10. c1 added 3 units and c2 just added 4. this is a total of 7 which means the 
    #additional_units_required_to_fill_my_case should be 3
    assert_equal 3, tote_item.additional_units_required_to_fill_my_case

    assert_response :redirect
    follow_redirect!
    assert_template 'postings/index'

    assert_not flash.empty?
    assert_equal "Tote item added", flash[:success]

    return posting

  end

  test "pout page should tell user more units necessary for order to go through" do
    come_up_3_short    
  end

  test "posting should remove unauthorized tote items when it transitions from open to closed when late adds not allowed" do
    
    c = users(:c_one_tote_item)
    tote_item = c.tote_items.first
    posting = tote_item.posting
        
    #let nature take its course. purchase should occur off the first checkout
    travel_to tote_item.posting.order_cutoff - 1.hour

    assert_equal ToteItem.states[:ADDED], tote_item.state
    
    100.times do

      RakeHelper.do_hourly_tasks

      if Time.zone.now == tote_item.posting.order_cutoff
        tote_item.reload
        assert_equal ToteItem.states[:REMOVED], tote_item.state
      end
      
      travel 1.hour

    end

    travel_back    
    
  end

  test "posting should recur" do
    
    price = 12.31
    #verify the post doesn't exist
    verify_post_presence(price, @unit, exists = false)

    #create the post, with recurrence
    login_for(@farmer)
    
    delivery_date = Time.zone.today.midnight + 14.days
    if delivery_date.wday == STARTOFWEEK
      delivery_date += 1.day
    end

    order_cutoff = delivery_date - 2.days
    posting = create_posting(@farmer, price, @product, @unit, delivery_date, order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil)

    #verify exactly one post exists
    verify_post_presence(price, @unit, exists = true, posting.id)
    #wind the clock forward to between the commitment zone start and delivery date
    posting = Posting.where(price: price).last

    #add a toteitem to this posting. this is necessary or the rake helper won't transition this posting to committed
    posting.tote_items.create(quantity: 2, price: price, state: ToteItem.states[:AUTHORIZED], user: users(:c1))

    last_minute = posting.order_cutoff - 10.minutes
    travel_to last_minute

    while Time.zone.now < posting.order_cutoff + 10.minutes
      top_of_hour = Time.zone.now.min == 0

      if top_of_hour
        RakeHelper.do_hourly_tasks        
      end

      #as long as we're prior to the commitment zone start of the first posting we should
      #be able to see the post on the shopping page
      if Time.zone.now < posting.order_cutoff
        verify_post_presence(price, @unit, true, posting.id)
      end

      last_minute = Time.zone.now
      travel 1.minute
    end

    #verify the old post is not visible
    #the old post should disappear from the postings page but the new one
    #should appear so that what you should actually find is there are now two postings in the
    #posting_recurrence.postings list but only one is visible in the postings page    
    assert_equal false, posting.posting_recurrence.postings.first.live
    assert_equal 2, posting.posting_recurrence.postings.count

   
    #verify the new post is visible
    verify_post_visibility(price, @unit, 1)
        
    travel_back
    
  end

  def verify_post_presence(price, unit, exists, posting_id = nil)

    if exists == true
      count = 1

      if posting_id.nil?
        posting = Posting.where(price: price)
      else
        posting = Posting.find posting_id
      end

      get postings_path(food_category: posting.product.food_category.name)
    else
      count = 0
    end

    verify_post_visibility(price, unit, count)    
    verify_post_existence(price, count, posting_id)

  end

  def verify_post_visibility(price, unit, count)
    if count > 0
      posting = Posting.where(price: price).first
      get postings_path(food_category: posting.product.food_category.name)
    else
      get postings_path
    end    
    
    assert :success
    verify_price_on_postings_page(price, unit, count)

  end

  def verify_post_existence(price, count, posting_id = nil)

    postings = Posting.where(price: price)
    assert_not postings.nil?
    assert_equal count, postings.count

    if posting_id != nil
      assert_equal posting_id, postings.last.id
    end

  end

  test "create new posting" do
    create_new_posting
  end

  test "edit new posting" do
    login_for(@farmer)
    mylive = @posting.live
    mynotlive = !@posting.live

    patch posting_path(@posting), params: {posting: {
      description: "edited description",
      price: @posting.price,
      live: mynotlive
    }}

    assert :success  
    assert_redirected_to @farmer    

  end

  #should copy an existing posting and have all same values and show up in the postings page
  test "should copy new posting" do
    login_for(@farmer)

    price = 2.75
    unit = units(:pound)    
    assert @posting.product.food_category

    get postings_path(food_category: @posting.product.food_category.name)
    assert :success
    verify_price_on_postings_page(price, unit, count = 1)

    #turn off the existing posting
    patch posting_path(@posting), params: {posting: {
      description: "edited description",
      price: @posting.price,
      live: false
    }}

    assert :success  
    assert_redirected_to @farmer
    get postings_path(food_category: @posting.product.food_category.name)
    assert :success
    assert_select '.price', {text: "$2.75 / Pound", count: 0}

    #here is where we need to copy the posting
    get new_posting_path, params: {posting_id: @posting.id}
    posting = assigns(:posting)
    post postings_path, params: {posting: {
      description: posting.description,
      price: posting.price,
      producer_net_unit: (posting.price * 0.90).round(2),
      user_id: posting.user_id,
      product_id: posting.product_id,      
      unit_id: posting.unit_id,
      live: posting.live,
      delivery_date: posting.delivery_date,
      order_cutoff: posting.order_cutoff
    }}

    get postings_path(food_category: posting.product.food_category.name)
    assert :success        
    verify_price_on_postings_page(price, posting.unit, count = 1)

  end

  def login_for(user)
    get_access_for(user)
    get login_path
    post login_path, params: {session: { email: @farmer.email, password: 'dogdog' }}
    assert_redirected_to root_path
    follow_redirect!
  end

  def create_standard_posting

    delivery_date = Time.zone.now.midnight + 7.days
    if delivery_date.wday == STARTOFWEEK
      delivery_date += 1.day
    end

    order_cutoff = delivery_date - 2.days

    posting = create_posting(@farmer, price = 0.83, product = @product, unit = @unit, delivery_date, order_cutoff, units_per_case = 10, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil)

    return posting

  end

  def create_new_posting

    login_for(@farmer)
    assert_response :success
    assert_template 'static_pages/home'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", subscriptions_path
    get new_posting_path

    delivery_date = Time.zone.today + 5.days
    if delivery_date.wday == STARTOFWEEK
      delivery_date += 1.day
    end

    price = 1.09    
    posting = create_posting(@farmer, price, @product, @unit, delivery_date, order_cutoff = delivery_date - 2.days, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil)
    
    return posting

  end
  
end
