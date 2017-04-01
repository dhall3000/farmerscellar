require 'test_helper'

class ToteItemTest < ActiveSupport::TestCase

  def setup
  	@tote_item = tote_items(:c1apple)
    creditor_order = CreditorOrder.new(delivery_date: @tote_item.posting.delivery_date, creditor: @tote_item.posting.get_creditor, order_value_producer_net: 1.0)
    creditor_order.postings << @tote_item.posting
    assert creditor_order.save    

    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.wday == STARTOFWEEK
      delivery_date = Time.zone.today + 4.days
    end

    @posting = Posting.new(units_per_case: 10, unit: @unit, product: @product, user: @farmer, description: "descrip", price: 1.25, live: true, order_cutoff: delivery_date - 2.days, delivery_date: delivery_date, producer_net_unit: 1.15)
    @posting.save

    creditor_order = CreditorOrder.new(delivery_date: @posting.delivery_date, creditor: @posting.get_creditor, order_value_producer_net: 1.0)
    creditor_order.postings << @posting
    assert creditor_order.save

  end

  test "should return correct answers when querying for legit state values" do

    ToteItem.states.values.each do |state_value|
      assert ToteItem.valid_state_values?([state_value])
    end    

    assert ToteItem.valid_state_values?(ToteItem.states.values)
    assert_not ToteItem.valid_state_values?([-1, ToteItem.states[:ADDED]])
    assert_not ToteItem.valid_state_values?(["hello", "goodbye"])

  end

  test "should report producer order minimum deficiency when posting and distributor order min met" do

    #get outstanding of posting
    #get outstanding of producer
    #get outstanding of distributor
    #return the biggest value

    nuke_all_postings
    nuke_all_users

    customer = create_user("bob", "bob@b.com")
    
    distributor = create_producer("distributor", "distributor@d.com")
    distributor.update(order_minimum_producer_net: 100)

    farm1 = create_producer("farmer1", "f1@f.com", distributor, 50, create_default_business_interface = false)
    price = 2
    posting_f1 = create_posting(farm1, price, products(:apples))
    posting_f1.update(order_minimum_producer_net: 10)
    quantity = 4
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_f1, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)
    assert_equal (quantity * price * 0.915).round(2), posting_f1.reload.inbound_order_value_producer_net
    assert_equal 0, posting_f1.outbound_order_value_producer_net

    farm2 = create_producer("farmer2", "f2@f.com", distributor, 0, create_default_business_interface = false)
    price = 2
    posting_f2 = create_posting(farm2, price, products(:milk))
    quantity = 45
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_f2, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    #verify that the amount left for the posting is > 0
    assert posting_f1.order_minimum_producer_net_outstanding > 0
    #verify that the amount left for the distributor is > 0
    assert distributor.order_minimum_producer_net_outstanding(posting_f1.order_cutoff) > 0

    #verify that the amount left for the producer is greater than the amount left for the posting
    assert farm1.order_minimum_producer_net_outstanding(posting_f1.order_cutoff) > posting_f1.order_minimum_producer_net_outstanding
    #verify that the amount left for the producer is greater than the amount left for the distributor
    assert farm1.order_minimum_producer_net_outstanding(posting_f1.order_cutoff) > distributor.order_minimum_producer_net_outstanding(posting_f1.order_cutoff)
    #verify the biggest amount outstanding reported by the posting is correct (hint: should be equal to farm1's order min minus posting1's inbound order value)
    assert_equal farm1.order_minimum_producer_net_outstanding(posting_f1.order_cutoff) - posting_f1.reload.inbound_order_value_producer_net, posting_f1.biggest_order_minimum_producer_net_outstanding

  end

  test "should report order amount remaining needed when distributor order minimum unmet" do

    nuke_all_postings
    nuke_all_users
    
    distributor = create_producer("distributor", "distributor@d.com")
    distributor.update(order_minimum_producer_net: 100)
    
    farm1 = create_producer("farmer1", "f1@f.com", distributor, order_min = 0, create_default_business_interface = false)
    farm2 = create_producer("farmer2", "f2@f.com", distributor, order_min = 0, create_default_business_interface = false)    
    farm3 = create_producer("farmer3", "f3@f.com", distributor, order_min = 0, create_default_business_interface = false)    
    
    customer = create_user("bob", "bob@b.com")
    make_some_orders(distributor, customer)
    make_some_orders(farm1, customer)
    make_some_orders(farm2, customer)
    make_some_orders(farm3, customer)

    order_cutoff = distributor.postings.first.order_cutoff
    assert_equal 0, distributor.outbound_order_value_producer_net(order_cutoff)
    #OM for the distributor is 100. distributor has 3 producers, each of which has 3 postings. the distributor himself also has 3 postings. the customer buys quantity of 4 from each of
    #the 12 postings. that's quantity of 48. the retail price is $2 so the retail producer net for the distributor is $96. multiply this by 0.915 to account for paypal fees
    #and FC commission and you have 87.84 for the distributor inbound order value
    assert_equal 87.84, distributor.reload.inbound_order_value_producer_net(order_cutoff)
    assert_equal (100 - 87.84).round(2), distributor.order_minimum_producer_net_outstanding(order_cutoff)
    
  end

  def make_some_orders(producer, customer)

    price = 2
    posting_a = create_posting(producer, price, products(:apples))
    posting_b = create_posting(producer, price, products(:milk))
    posting_c = create_posting(producer, price, products(:celery))

    quantity = 4
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_a, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_b, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_c, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)
    
  end

  test "should report order amount remaining needed when producer order minimum unmet" do
    
    nuke_all_postings
    producer = create_producer("john", "john@j.com")
    producer.update(order_minimum_producer_net: 100)
    price = 5
    posting_a = create_posting(producer, price, products(:apples))
    posting_b = create_posting(producer, price, products(:milk))
    posting_c = create_posting(producer, price, products(:celery))

    customer = create_user("bob", "bob@b.com")

    quantity = 5
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_a, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_b, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting_c, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    retail = quantity * 3 * price

    assert producer.inbound_order_value_producer_net(posting_a.order_cutoff) > 0
    assert producer.inbound_order_value_producer_net(posting_a.order_cutoff) < producer.order_minimum_producer_net
    assert_equal 0, producer.outbound_order_value_producer_net(posting_a.order_cutoff)
    assert producer.order_minimum_producer_net_outstanding(posting_a.order_cutoff) > 0
    assert producer.order_minimum_producer_net_outstanding(posting_a.order_cutoff) < producer.order_minimum_producer_net

    #the sum of the posting values + the producer's amount outstanding equals the producers order minimum
    assert_equal producer.order_minimum_producer_net, (posting_a.outbound_order_value_producer_net * 3).round(2) + producer.order_minimum_producer_net_outstanding(posting_a.order_cutoff)
    
  end

  test "should report order amount remaining needed when posting order minimum unmet" do

    nuke_all_postings
    producer = create_producer("john", "john@j.com")
    delivery_date = get_delivery_date(7)
    price = 5
    order_minimum_producer_net = 100
    posting = create_posting(producer, price, product = nil, unit = nil, delivery_date, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net)
    customer = create_user("bob", "bob@b.com")
    quantity = 10
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    expected_order_min_outstanding = (posting.order_minimum_producer_net - posting.inbound_order_value_producer_net).round(2)
    assert expected_order_min_outstanding > 0
    assert expected_order_min_outstanding < posting.order_minimum_producer_net
    assert_equal 0, posting.outbound_order_value_producer_net
    assert_equal expected_order_min_outstanding, posting.order_minimum_producer_net_outstanding

  end

  test "should report order amount remaining is zero when posting does not have order minimum" do

    nuke_all_postings
    producer = create_producer("john", "john@j.com")
    delivery_date = get_delivery_date(7)
    price = 5    
    posting = create_posting(producer, price, products(:apples), units(:pound), delivery_date, delivery_date - 2.days, commission = 0.05)    
    customer = create_user("bob", "bob@b.com")
    quantity = 10
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.state?(:AUTHORIZED)

    expected_order_min_outstanding = 0
    assert_equal 0, expected_order_min_outstanding
    assert_not posting.order_minimum_producer_net.nil?
    assert posting.outbound_order_value_producer_net > 0
    assert_equal 0, posting.order_minimum_producer_net_outstanding

  end

  test "should report order amount remaining is zero when posting order minimum met" do

    nuke_all_postings
    producer = create_producer("john", "john@j.com")
    delivery_date = get_delivery_date(7)
    price = 5
    order_minimum_producer_net = 100
    posting = create_posting(producer, price, product = nil, unit = nil, delivery_date, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net)
    customer = create_user("bob", "bob@b.com")
    quantity = 25
    ti = ToteItem.new(quantity: quantity, price: price, state: ToteItem.states[:ADDED], posting: posting, user: customer)
    assert ti.save
    ti.transition(:customer_authorized)
    assert ti.reload.state?(:AUTHORIZED)

    expected_order_min_outstanding = [0, (posting.order_minimum_producer_net - posting.inbound_order_value_producer_net).round(2)].max
    assert_equal 0, expected_order_min_outstanding
    assert posting.outbound_order_value_producer_net > order_minimum_producer_net
    assert_equal expected_order_min_outstanding, posting.order_minimum_producer_net_outstanding

  end

  test "base level toteitemshelper methods should return correct values" do

    #test get_gross_cost
    quantity = 13
    price = 21.07
    expected_gross_cost = 273.91
    assert_equal expected_gross_cost, ToteItemsController.helpers.get_gross_cost(quantity, price)    

    #test get_commission_item
    expected_price = 2.75
    expected_quantity = 3
    expected_commission_factor = 0.048
    #if you use a calculator to multiply the above three numbers you get 0.4125.    
    #rounded to 2 places you'd get 0.41. so why 0.42 for 'expected'? because we compute
    #based off a single unit and then multiply from there. so in this example you'd compute
    #the commission per unit and round that to 2 places. then you'd multiply that result by
    #the quantity which is 3. like this:
    #2.75 * 0.05 = 0.1375
    #0.1375 rounded 2 places is 0.14
    #0.14 * 3 = 0.42
    expected_commission = 0.42
    assert_equal expected_commission_factor, @posting.get_commission_factor    
    assert_equal expected_price, @tote_item.price
    assert_equal expected_quantity, @tote_item.quantity
    assert_equal expected_commission, ToteItemsController.helpers.get_commission_item(@tote_item)
    
    #test get_commission_item filled = true
    expected_price = 2.75
    expected_commission_factor = 0.05
    expected_quantity = 4
    @tote_item.quantity_filled = expected_quantity
    expected_commission = 0.56
    assert_equal expected_commission, ToteItemsController.helpers.get_commission_item(@tote_item, filled = true)

    #test get_payment_processor_fee_unit
    #unit price is 2.75
    #fee rate is 0.035
    #multiplied is 0.09625
    #rounded 2 is 0.10
    expected_payment_processor_fee_unit = 0.10
    assert_equal expected_payment_processor_fee_unit, ToteItemsController.helpers.get_payment_processor_fee_unit(@tote_item.price)

    #test get_payment_processor_fee_item
    expected_payment_processor_fee_item = 0.30
    assert_equal expected_payment_processor_fee_item, ToteItemsController.helpers.get_payment_processor_fee_item(@tote_item)

    #test get_payment_processor_fee_item filled = true
    expected_quantity = 4
    @tote_item.quantity_filled = expected_quantity
    expected_payment_processor_fee_item = 0.40
    assert_equal expected_payment_processor_fee_item, ToteItemsController.helpers.get_payment_processor_fee_item(@tote_item, filled = true)

  end

  test "partial shipping added item should still report partial ship after authorization" do

    assert_equal 0, @posting.tote_items.count

    #three merry shoppers come along and add+auth a total of quantity 6
    c1 = users(:c1)
    ti = create_tote_item(c1, @posting, 3)
    create_one_time_authorization_for_customer(c1)
    assert_equal 7, ti.additional_units_required_to_fill_my_case

    c2 = users(:c2)
    ti = create_tote_item(c2, @posting, 1)
    create_one_time_authorization_for_customer(c2)
    assert_equal 6, ti.additional_units_required_to_fill_my_case

    c3 = users(:c3)
    ti = create_tote_item(c3, @posting, 2)
    create_one_time_authorization_for_customer(c3)
    assert_equal 4, ti.additional_units_required_to_fill_my_case

    #then c4 comes along and adds 5. this fills the first case with quantity 1 left over for the 2nd case
    c4 = users(:c4)
    ti = create_tote_item(c4, @posting, 5)
    #consequently, we should report '9' remaining to fill the 2nd case
    assert_equal 9, ti.additional_units_required_to_fill_my_case
    #and if nothing changes, this item will partially fill
    assert ti.will_partially_fill?
    #now c4 authorizes...
    ti.transition(:customer_authorized)
    ti.reload
    assert ti.state?(:AUTHORIZED)
    #and if nothing changes, this item should still report will partially fill
    assert ti.will_partially_fill?

  end

  test "should tell user first added item will ship but second added item will not ship" do
    #user auths 3 of a 10-unit-case posting. then c1 adds 3 so that 4 more are needed then c1 adds 5 so that his first item should get
    #shipped if he authorizes but the second item should report 9 more needed to ship.    
    assert_equal 0, @posting.tote_items.count

    c4 = users(:c4)
    ti = create_tote_item(c4, @posting, 3)
    create_one_time_authorization_for_customer(c4)
    assert_equal 7, ti.additional_units_required_to_fill_my_case
    
    c1 = users(:c1)
    ti3 = create_tote_item(c1, @posting, 3)
    assert_equal 4, ti3.additional_units_required_to_fill_my_case

    ti5 = create_tote_item(c1, @posting, 5)
    assert_equal 9, ti5.additional_units_required_to_fill_my_case

    #if the user auth'd right now ti3 should fully fill. only ti5 should partially fill
    assert_equal 0, ti3.additional_units_required_to_fill_my_case
    
  end

  test "users first item should be shippable but not the second" do
    #make a test where anonymouse user auths 3 of a 10-unit-case posting. then c1 adds 3 so that 4 more are needed then c1 adds 5 so that his first item should
    #get shipped if he authorizes but the second item should report 9 more needed to ship.
    c2 = users(:c2)
    tic2 = create_tote_item(c2, @posting, quantity = 3)
    create_one_time_authorization_for_customer(c2)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case

    c1 = users(:c1)
    tic1_1 = create_tote_item(c1, @posting, quantity = 3)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case
    assert_equal 4, tic1_1.additional_units_required_to_fill_my_case  

    tic1_2 = create_tote_item(c1, @posting, quantity = 5)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case
    assert_equal 0, tic1_1.additional_units_required_to_fill_my_case  
    assert_equal 9, tic1_2.additional_units_required_to_fill_my_case  

  end

  test "should say authorized item will ship but added item will not ship" do
    #what happens if user auths an item, then that case fully fills with others' auth'd items. then user comes and adds another item such that
    #this last item's case isn't filled. will it say that the user's original auth'd item comes up short?

    c1 = users(:c1)
    ti1 = create_tote_item(c1, @posting, quantity = 3)
    create_one_time_authorization_for_customer(c1)
    assert_equal 7, ti1.additional_units_required_to_fill_my_case

    c4 = users(:c4)
    ti2 = create_tote_item(c4, @posting, quantity = 7)
    create_one_time_authorization_for_customer(c4)
    assert_equal 0, ti1.additional_units_required_to_fill_my_case
    assert_equal 0, ti2.additional_units_required_to_fill_my_case    

    ti3 = create_tote_item(c1, @posting, quantity = 2)
    assert_equal 0, ti1.additional_units_required_to_fill_my_case
    assert_equal 0, ti2.additional_units_required_to_fill_my_case
    assert_equal 8, ti3.additional_units_required_to_fill_my_case

  end

  test "should partially fill" do

    assert_equal 0, @tote_item.purchase_receivables.count

    assert_equal ToteItem.states[:ADDED], @tote_item.state
    @tote_item.transition(:customer_authorized)
    @tote_item.transition(:order_cutoffed)
    @tote_item.posting.fill(@tote_item.quantity / 2)

    @tote_item.reload
    assert_equal ToteItem.states[:FILLED], @tote_item.state
    assert @tote_item.quantity_filled < @tote_item.quantity
    assert_equal @tote_item.quantity / 2, @tote_item.quantity_filled

    assert_equal 1, @tote_item.purchase_receivables.count
    assert @tote_item.purchase_receivables.last.amount > 0

    assert @tote_item.purchase_receivables.last.amount < ToteItemsController.helpers.get_gross_item(@tote_item), "The PurchaseReceivable amount is #{@tote_item.purchase_receivables.last.amount.to_s} but should be less than the get_gross_item amount which is #{ToteItemsController.helpers.get_gross_item(@tote_item).to_s}"

  end

  test "should return all users as having zero deliveries later this week" do

    #make all items' state be ADDED
    ToteItem.all.update_all(state: ToteItem.states[:ADDED])
    #move delivery date
    travel_to Time.zone.now - 1000.days
    #verify method returns nothing
    users = ToteItem.get_users_with_no_deliveries_later_this_week
    assert_equal User.count, users.count
    #rinse and repeat 
    travel_back
    travel_to Time.zone.now + 1000.days
    #verify method returns nothing
    users = ToteItem.get_users_with_no_deliveries_later_this_week
    assert_equal User.count, users.count

    travel_back

  end

  test "should return some users as having zero deliveries later this week" do
    
    #make all items' state be AUTHORIZED    
    ToteItem.all.each do |tote_item|
      tote_item.transition(:customer_authorized)
    end
    #move delivery date to 1 day before one of the posting delivery dates
    travel_to ToteItem.first.posting.delivery_date - 1.day
    #verify that some users have delivery later this week
    users = ToteItem.get_users_with_no_deliveries_later_this_week
    assert users.count < User.count

    travel_back    

  end

  test "should create purchase receivable object" do
    pr_count = PurchaseReceivable.count
    @tote_item.update(state: ToteItem.states[:ADDED])
    @tote_item.transition(:customer_authorized)
    @tote_item.transition(:order_cutoffed)    
    @tote_item.reload
    @tote_item.posting.fill(@tote_item.quantity)
    assert_equal pr_count + 1, PurchaseReceivable.count    
    tote_item_value = (@tote_item.price * @tote_item.quantity).round(2)
    pr = @tote_item.purchase_receivables.last
    assert_equal pr.amount, tote_item_value
  end

  #TODO: add more transitions tests
  test "transitions" do
    assert_equal ToteItem.states[:ADDED], @tote_item.state
    @tote_item.transition(:customer_authorized)
    assert_equal ToteItem.states[:AUTHORIZED], @tote_item.state
    @tote_item.reload
    assert_equal ToteItem.states[:AUTHORIZED], @tote_item.state
  end

  test "state method checker" do
    assert @tote_item.state?(:ADDED)
    @tote_item.state = ToteItem.states[:AUTHORIZED]
    assert @tote_item.state?(:AUTHORIZED)    
  end

  test "should deauthorize" do
    assert_equal ToteItem.states[:ADDED], @tote_item.state
    @tote_item.transition(:customer_authorized)
    @tote_item.save
    ti = @tote_item.reload
    assert_equal ToteItem.states[:AUTHORIZED], @tote_item.state
    ti.transition(:billing_agreement_inactive)
    ti = @tote_item.reload
    assert_equal ToteItem.states[:ADDED], @tote_item.state
  end

  test "should not deauthorize" do
    @tote_item.state = ToteItem.states[:COMMITTED]
    assert @tote_item.state?(:COMMITTED)    
    @tote_item.transition(:billing_agreement_inactive)
    assert_not @tote_item.state?(:ADDED)
  end

  test "should be valid" do
  	assert @tote_item.valid?  	
  end

  test "posting should be present" do
  	@tote_item.posting = nil
  	assert_not @tote_item.valid?
  end

  test "user should be present" do
  	@tote_item.user = nil
  	assert_not @tote_item.valid?
  end

  test "price should be present" do
  	@tote_item.price = nil
  	assert_not @tote_item.valid?
  end

  test "price should be greater than zero" do
  	@tote_item.price = 0
  	assert_not @tote_item.valid?
  	@tote_item.price = -1
  	assert_not @tote_item.valid?
  end

  test "price can be a float value" do
  	@tote_item.price = 1.5
  	assert @tote_item.valid?
  	assert @tote_item.price > 1
  	assert @tote_item.price < 2
  end

  test "quantity should be present" do
  	@tote_item.quantity = nil
  	assert_not @tote_item.valid?
  end

  test "quantity should be greater than zero" do
  	@tote_item.quantity = 0
  	assert_not @tote_item.valid?
  	@tote_item.quantity = -1
  	assert_not @tote_item.valid?
  end

  test "quantity should be an integer" do
  	@tote_item.quantity = 1.5
  	assert_not @tote_item.valid?
  end

  test "state should be present" do
  	@tote_item.state = nil
  	assert_not @tote_item.valid?
  end

  test "state should be integer" do
  	@tote_item.state = 1.5
  	assert_not @tote_item.valid?
  end

  test "state should be within range" do
  	@tote_item.state = 9
  	assert @tote_item.valid?
  	@tote_item.state = 1
  	assert @tote_item.valid?
  	@tote_item.state = 2
  	assert @tote_item.valid?
  	@tote_item.state = 3
    #NOTE: this assert_not is accidentally brilliant. leaving this here will ensure that down the road no dev
    #wanting to add a new state to ToteItem class will use the value '3'. Using 3 would be bad because, since it
    #was once upon a time used, there will be 3's in the production database so if you (Mr. Dev, whoever you are),
    #in the future use 3 again, your logic will work great in dev but break in production
  	assert_not @tote_item.valid?
  	@tote_item.state = 4
  	assert @tote_item.valid?
  	@tote_item.state = 5
  	assert @tote_item.valid?
  	@tote_item.state = 6
  	assert @tote_item.valid?
  	@tote_item.state = 7
    #NOTE: this assert_not is accidentally brilliant. leaving this here will ensure that down the road no dev
    #wanting to add a new state to ToteItem class will use the value '7'. Using 7 would be bad because, since it
    #was once upon a time used, there will be 7's in the production database so if you (Mr. Dev, whoever you are),
    #in the future use 8 again, your logic will work great in dev but break in production    
  	assert_not @tote_item.valid?
  	@tote_item.state = 8
    #NOTE: this assert_not is accidentally brilliant. leaving this here will ensure that down the road no dev
    #wanting to add a new state to ToteItem class will use the value '8'. Using 8 would be bad because, since it
    #was once upon a time used, there will be 8's in the production database so if you (Mr. Dev, whoever you are),
    #in the future use 8 again, your logic will work great in dev but break in production    
  	assert_not @tote_item.valid?
    @tote_item.state = 10
    assert_not @tote_item.valid?

  	@tote_item.state = -1
  	assert_not @tote_item.valid?
  	@tote_item.state = 12
  	assert_not @tote_item.valid?
  end

end
