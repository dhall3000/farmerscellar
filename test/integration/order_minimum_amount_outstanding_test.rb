require 'integration_helper'

class OrderMinimumAmountOutstandingTest < IntegrationHelper

  def setup
    nuke_all_postings
  end

  #NOTE: hereafter "biggest_order_minimum_producer_net_outstanding" will be abbreviated as bomp

  test "biggest order min outstanding should reflect current state 1" do
    setup2(distributor_om = 200, producer1_om = 50, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 15, posting2_quantity = 0, posting3_quantity = 0)    
    assert_equal 185, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 2" do
    setup2(distributor_om = 200, producer1_om = 100, posting1_om = 50, posting1_units_per_case = 1, posting1_quantity = 15, posting2_quantity = 15, posting3_quantity = 15)    
    assert_equal 155, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 3" do
    setup2(distributor_om = 0, producer1_om = 50, posting1_om = 90, posting1_units_per_case = 1, posting1_quantity = 70, posting2_quantity = 0, posting3_quantity = 0)
    assert_equal 20, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 4" do
    setup2(distributor_om = 0, producer1_om = 30, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 15, posting2_quantity = 20, posting3_quantity = 0)
    assert_equal 5, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 5" do
    setup2(distributor_om = 0, producer1_om = 30, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 5, posting2_quantity = 20, posting3_quantity = 0)
    assert_equal 15, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 6" do
    setup2(distributor_om = 0, producer1_om = 30, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 15, posting2_quantity = 5, posting3_quantity = 0)
    assert_equal 10, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 7" do
    setup2(distributor_om = 100, producer1_om = 0, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 5, posting2_quantity = 15, posting3_quantity = 10)
    assert_equal 70, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 8" do
    setup2(distributor_om = 100, producer1_om = 0, posting1_om = 20, posting1_units_per_case = 1, posting1_quantity = 5, posting2_quantity = 80, posting3_quantity = 10)
    assert_equal 15, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 9" do
    setup2(distributor_om = 100, producer1_om = 0, posting1_om = 0, posting1_units_per_case = 20, posting1_quantity = 5, posting2_quantity = 80, posting3_quantity = 10)
    assert_equal 15, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 10" do
    setup2(distributor_om = 100, producer1_om = 0, posting1_om = 10, posting1_units_per_case = 20, posting1_quantity = 5, posting2_quantity = 80, posting3_quantity = 10)
    assert_equal 15, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 11" do
    setup2(distributor_om = 100, producer1_om = 10, posting1_om = 10, posting1_units_per_case = 6, posting1_quantity = 11, posting2_quantity = 80, posting3_quantity = 10)
    assert_equal 1, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 12" do
    #TODO: this case doesn't work. posting.biggest_order_minimum_producer_net_outstanding needs to be adjusted to handle this special case. moving on for now.
    #setup2(distributor_om = 0, producer1_om = 50, posting1_om = 0, posting1_units_per_case = 20, posting1_quantity = 55, posting2_quantity = 0, posting3_quantity = 0)
    #assert_equal 5, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  test "biggest order min outstanding should reflect current state 13" do
    #TODO: this case doesn't work. posting.biggest_order_minimum_producer_net_outstanding needs to be adjusted to handle this special case. moving on for now.
    #setup2(distributor_om = 0, producer1_om = 50, posting1_om = 0, posting1_units_per_case = 40, posting1_quantity = 65, posting2_quantity = 0, posting3_quantity = 0)
    #assert_equal 15, @posting1.biggest_order_minimum_producer_net_outstanding
  end

  def setup2(distributor_om = 0, producer1_om = 0, posting1_om = 0, posting1_units_per_case = 1, posting1_quantity = 0, posting2_quantity = 0, posting3_quantity = 0)
    @distributor = create_distributor(name = "distributor name", email = "distributor@d.com", order_min = distributor_om)

    @producer1 = create_producer(name = "producer1", email = "producer1@p.com", distributor = @distributor, order_min = producer1_om)
    @producer2 = create_producer(name = "producer2", email = "producer2@p.com", distributor = @distributor, order_min = 0)

    @delivery_date = get_delivery_date(7)
    @order_cutoff = @delivery_date - 2.days

    @posting1 = create_posting(@producer1, price = 1.04, Product.create(name: "Product1"), unit = nil, @delivery_date, @order_cutoff, units_per_case = posting1_units_per_case, frequency = 1, order_minimum_producer_net = posting1_om, product_id_code = nil, commission = 0)
    @posting2 = create_posting(@producer1, price = 1.04, Product.create(name: "Product2"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, commission = 0)
    @posting3 = create_posting(@producer2, price = 1.04, Product.create(name: "Product3"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, commission = 0)

    @user = create_user

    if posting1_quantity > 0
      ti = create_tote_item(@user, @posting1, posting1_quantity)
      assert ti.state?(:ADDED)
      ti.transition(:customer_authorized)
      assert ti.state?(:AUTHORIZED)
    end

    if posting2_quantity > 0
      ti = create_tote_item(@user, @posting2, posting2_quantity)
      assert ti.state?(:ADDED)
      ti.transition(:customer_authorized)
      assert ti.state?(:AUTHORIZED)
    end

    if posting3_quantity > 0
      ti = create_tote_item(@user, @posting3, posting3_quantity)
      assert ti.state?(:ADDED)
      ti.transition(:customer_authorized)
      assert ti.state?(:AUTHORIZED)
    end

    @posting1.reload
    @posting2.reload
    @posting3.reload

  end

  test "bomp should be distributor order minimum producer net when no items have been ordered" do
    setup1

    postings = @distributor.reload.postings_by_delivery_date(@delivery_date)
    postings.each do |posting|
      assert_equal @distributor.order_minimum_producer_net, posting.biggest_order_minimum_producer_net_outstanding
    end
    
  end

  test "bomp for posting5 should diminish in step with order accruals on posting6" do
    setup1

    user = create_user

    20.times do
      ti = create_tote_item(user, @posting6, 10)
      create_rt_authorization_for_customer(user)
      p6_order_value = @posting6.reload.outbound_order_value_producer_net
      assert_equal [@distributor.order_minimum_producer_net - p6_order_value, 0].max, @posting5.biggest_order_minimum_producer_net_outstanding
    end

  end

  test "bomp for posting5 should diminish in step with order accruals on posting7" do
    setup1

    assert_equal @distributor.order_minimum_producer_net, @posting5.biggest_order_minimum_producer_net_outstanding
    user = create_user
    ti = create_tote_item(user, @posting7, 11)
    create_rt_authorization_for_customer(user)
    assert @posting5.biggest_order_minimum_producer_net_outstanding < @distributor.order_minimum_producer_net

    while ((om = @posting5.biggest_order_minimum_producer_net_outstanding) > 0)
      ti = create_tote_item(user, @posting7, 1)
      create_rt_authorization_for_customer(user)
      assert @posting5.biggest_order_minimum_producer_net_outstanding < om
    end

  end

  test "removing one unit from posting1 should cause posting 5 bomp to increase by producer1 om" do
    setup1
    #here's the setup: posting3 has 5 units ordered, posting 1 has 10 unites ordered, posting6 has 17 units ordered
    user = create_user
    ti = create_tote_item(user, @posting3, 5)    
    create_rt_authorization_for_customer(user)
    assert_equal 5, @posting3.inbound_num_units_ordered
    posting6_quantity = 17
    ti = create_tote_item(user, @posting6, posting6_quantity)    
    create_rt_authorization_for_customer(user)
    assert_equal posting6_quantity, @posting6.inbound_num_units_ordered
    ti = create_tote_item(user, @posting1, 9)
    create_rt_authorization_for_customer(user)
    ti = create_tote_item(user, @posting1, 1)
    create_rt_authorization_for_customer(user)
    assert_equal 10, @posting1.inbound_num_units_ordered
    assert @posting1.reload.outbound_order_value_producer_net > 0
    #this should make it so that producer1 and distributor's oms are met. verify by checkign that posting5.bomp is zero.
    assert_equal 0, @posting5.biggest_order_minimum_producer_net_outstanding
    #and that distributor is set to ship product
    assert @distributor.outbound_order_value_producer_net(@order_cutoff) > 0
    #then REMOVE a one-unit tote item from posting1.
    remove_tote_item(ti)
    assert ti.reload.state?(:REMOVED)
    #this should cause the entire case to not ship which should move producer1
    assert_equal 0, @posting1.reload.outbound_order_value_producer_net
    #below his om so all $50 should drop off
    assert_equal 0, @producer1.outbound_order_value_producer_net(@order_cutoff)
    #which would put distributor below his om so posting5.bomp should spike > 0 to around $50
    assert_equal 0, @distributor.outbound_order_value_producer_net(@order_cutoff)
  end

  test "a case 1 shy of full should cause entire order to roll till next cycle when another unit addition triggers all to ship" do
    setup1
    #what we're testing here is that order value tracking persists as roll till filled orders roll into the next week's cycle due to unmet order mins.
    #we're going to use most of the setup from this situation: test "removing one unit from posting1 should cause posting 5 bomp to increase by producer1 om" do
    setup1
    #but we're going to make it so that in cycle on there's a any unit insuficciency on @posting1's sheet so that causes all the distributors orders to roll till next cycle    
    user = create_user
    posting6_quantity = 17

    ti = create_tote_item(user, @posting1, 9, frequency = nil, roll_until_filled = true)
    ti = create_tote_item(user, @posting3, 5, frequency = nil, roll_until_filled = true)
    ti = create_tote_item(user, @posting6, posting6_quantity, frequency = nil, roll_until_filled = true)

    create_rt_authorization_for_customer(user)
    @posting1.reload
    @posting3.reload
    @posting6.reload

    assert_equal 9, @posting1.total_quantity_authorized_or_committed
    assert_equal 5, @posting3.inbound_num_units_ordered
    assert_equal posting6_quantity, @posting6.inbound_num_units_ordered
    assert_equal 0, @posting1.outbound_order_value_producer_net
    assert @posting3.outbound_order_value_producer_net > 0
    assert @posting6.outbound_order_value_producer_net > 0
    assert_equal 0, @distributor.outbound_order_value_producer_net(@order_cutoff)

    #ok, now let's move to cycle two...
    travel_to @order_cutoff
    #and roll all the postings...
    RakeHelper.do_hourly_tasks
    #now verify order min stuff state is as it was
    p1_current = @posting1.posting_recurrence.current_posting    
    p3_current = @posting3.posting_recurrence.current_posting   
    p6_current = @posting6.posting_recurrence.current_posting

    assert_not_equal p1_current, @posting1
    assert_not_equal p3_current, @posting3
    assert_not_equal p6_current, @posting6

    assert_equal 9, p1_current.total_quantity_authorized_or_committed
    assert_equal 5, p3_current.inbound_num_units_ordered
    assert_equal posting6_quantity, p6_current.inbound_num_units_ordered        
    assert_equal 0, p1_current.outbound_order_value_producer_net
    assert p3_current.outbound_order_value_producer_net > 0
    assert p6_current.outbound_order_value_producer_net > 0
    assert_equal 0, @producer1.reload.outbound_order_value_producer_net(@order_cutoff)
    assert_equal 0, @distributor.reload.outbound_order_value_producer_net(@order_cutoff)
    
    #now add one unit to p1_current
    ti = create_tote_item(user, p1_current, 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(user)

    #now verify that an order is indeed set to ship
    assert_equal 10, p1_current.inbound_num_units_ordered
    assert_equal 5, p3_current.inbound_num_units_ordered
    assert_equal posting6_quantity, p6_current.inbound_num_units_ordered        
    assert p1_current.reload.outbound_order_value_producer_net > 0
    assert p3_current.reload.outbound_order_value_producer_net > 0
    assert p6_current.reload.outbound_order_value_producer_net > 0
    assert @producer1.reload.outbound_order_value_producer_net(p1_current.order_cutoff) > 0
    assert @distributor.reload.outbound_order_value_producer_net(p1_current.order_cutoff) > 0

    #customer changes mind, removes one unit from p1_current
    remove_tote_item(ti)
    #now entire shipment should be off once again
    assert_equal 9, p1_current.total_quantity_authorized_or_committed
    assert_equal 5, p3_current.inbound_num_units_ordered
    assert_equal posting6_quantity, p6_current.inbound_num_units_ordered        

    assert_equal 0, p1_current.reload.outbound_order_value_producer_net
    assert p3_current.outbound_order_value_producer_net > 0
    assert p6_current.outbound_order_value_producer_net > 0
    assert_equal 0, @producer1.reload.outbound_order_value_producer_net(@order_cutoff)
    assert_equal 0, @distributor.reload.outbound_order_value_producer_net(@order_cutoff)    

    travel_back
  end

  test "bomp value should walk down the stack from distributor to producer and finally to case constrained posting" do
    setup1
    #posting 1 has case, producer OM and distributor OM standing in it's way. the initial monetary size of these increases in that order as well. this test
    #is going to demonstrate that we can knock those inhibitions out in reverse order. we'll do like this:
    
    #ping posting1.bomp to verify it's equal to distributor ompn
    assert_equal @distributor.order_minimum_producer_net, @posting1.biggest_order_minimum_producer_net_outstanding
    #order from posting 5 to make it so distributor.bomp < producer1.bomp.
    user = create_user
    ti = create_tote_item(user, @posting5, 25)
    create_rt_authorization_for_customer(user)
    #now ping posting1 and verify bomp == producer1.bomp.
    assert_equal @producer1.order_minimum_producer_net, @posting1.biggest_order_minimum_producer_net_outstanding
    #now order from posting3
    ti = create_tote_item(user, @posting3, 1)
    create_rt_authorization_for_customer(user)
    #and verify posting1.bomp diminishes still further.
    assert @posting1.biggest_order_minimum_producer_net_outstanding < @producer1.order_minimum_producer_net
    #but also verify that posting1.bomp is greater than posting1's case constraint value
    assert @posting1.biggest_order_minimum_producer_net_outstanding > @posting1.get_producer_net_case    
    prior_posting1_bomp = @posting1.biggest_order_minimum_producer_net_outstanding
    #now order some from posting2 but less than posting2.ompn
    ti = create_tote_item(user, @posting2, 1)
    create_rt_authorization_for_customer(user)
    #and verify posting1.bomp remains unchanged
    assert_equal prior_posting1_bomp, @posting1.biggest_order_minimum_producer_net_outstanding
    #now order again from posting2, up over its bomp
    ti = create_tote_item(user, @posting2, 4)
    create_rt_authorization_for_customer(user)
    assert_equal 0, @posting2.reload.biggest_order_minimum_producer_net_outstanding
    #and verify posting1.bomp is now the case constraint
    assert_equal @posting1.get_producer_net_case, @posting1.biggest_order_minimum_producer_net_outstanding

  end

  def setup1
    @distributor = create_distributor(name = "distributor name", email = "distributor@d.com", order_min = 200)

    @producer1 = create_producer(name = "producer1", email = "producer1@p.com", distributor = @distributor, order_min = 50)
    @producer2 = create_producer(name = "producer2", email = "producer2@p.com", distributor = @distributor, order_min = 0)
    @producer3 = create_producer(name = "producer3", email = "producer3@p.com", distributor = @distributor, order_min = 100)

    @delivery_date = get_delivery_date(7)
    @order_cutoff = @delivery_date - 2.days

    @posting1 = create_posting(@producer1, price = 1, Product.create(name: "Product1"), unit = nil, @delivery_date, @order_cutoff, units_per_case = 10, frequency = 1, order_minimum_producer_net = 0)
    @posting2 = create_posting(@producer1, price = 10, Product.create(name: "Product2"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 20)
    @posting3 = create_posting(@producer1, price = 10, Product.create(name: "Product3"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)

    @posting4 = create_posting(@producer2, price = 10, Product.create(name: "Product4"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)
    @posting5 = create_posting(@producer2, price = 10, Product.create(name: "Product5"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)
    @posting6 = create_posting(@producer2, price = 10, Product.create(name: "Product6"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)

    @posting7 = create_posting(@producer3, price = 10, Product.create(name: "Product7"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)
    @posting8 = create_posting(@producer3, price = 10, Product.create(name: "Product8"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)
    @posting9 = create_posting(@producer3, price = 10, Product.create(name: "Product9"), unit = nil, @delivery_date, @order_cutoff, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0)
  end

end