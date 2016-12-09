require 'test_helper'
require 'utility/rake_helper'

class PostingTest < ActiveSupport::TestCase
  include ToteItemsHelper

  def setup

    @user = users(:c1)
    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.sunday?
      delivery_date = Time.zone.today + 4.days
    end

    @posting = Posting.new(unit: @unit, product: @product, user: @farmer, description: "descrip", price: 1.25, live: true, order_cutoff: delivery_date - 2.days, delivery_date: delivery_date)
    @posting.save

  end

  test "validate validations" do

    assert @posting.valid?

    #description_body
    tester = @posting.dup
    assert tester.valid?
    tester.description_body = nil
    tester.description_body = 6 #seems to me like this shouldn't be allowed but somehow it still passes validation
    assert tester.valid?

    #price
    tester = @posting.dup
    assert tester.valid?
    tester.price = nil
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.price = -1.0
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.price = "hello"
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.price = 1.0
    assert tester.valid?

    #delivery_date
    tester = @posting.dup    
    assert tester.valid?
    tester.delivery_date = nil
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.delivery_date = Time.zone.now - 1.day
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.delivery_date = "hello"
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.delivery_date = 78
    assert_not tester.valid?

    #TODO: there should be a test that delivery date is not on Sunday. too lazy...

    #order_cutoff
    tester = @posting.dup    
    assert tester.valid?
    tester.order_cutoff = nil
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.order_cutoff = tester.delivery_date + 1.day
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.order_cutoff = "hello"
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.order_cutoff = 78
    assert_not tester.valid?

    #state
    tester = @posting.dup    
    assert tester.valid?
    tester.state = nil
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.state = -1
    assert_not tester.valid?

    tester = @posting.dup    
    assert tester.valid?
    tester.state = 10
    assert_not tester.valid?

    #description
    tester = @posting.dup
    assert tester.valid?
    tester.description = nil    
    assert_not tester.valid?

    #price_body
    tester = @posting.dup
    assert tester.valid?
    tester.price_body = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.price_body = "hello"
    assert tester.valid?

    #unit_body
    tester = @posting.dup
    assert tester.valid?
    tester.unit_body = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.unit_body = "hello"
    assert tester.valid?

    #units_per_case
    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = "hello"
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = 0
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = -1
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = 1.5
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = 1
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.units_per_case = 10
    assert tester.valid?

    #product_id_code
    tester = @posting.dup
    assert tester.valid?
    tester.product_id_code = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.product_id_code = "hello"
    assert tester.valid?

    #order_minimum_producer_net
    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = "hello"
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = 0
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = -1
    assert_not tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = 1.5
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = 1
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.order_minimum_producer_net = 10
    assert tester.valid?

    #important_notes
    tester = @posting.dup
    assert tester.valid?
    tester.important_notes = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.important_notes = "hello"
    assert tester.valid?

    #important_notes_body
    tester = @posting.dup
    assert tester.valid?
    tester.important_notes_body = nil    
    assert tester.valid?

    tester = @posting.dup
    assert tester.valid?
    tester.important_notes = nil
    tester.important_notes_body = "hello body"
    #notice we're asserting not. the reason is because it's illegal to have a _body without the 'title'
    #(can't have important_notes_body without having importante_notes)
    assert_not tester.valid?

  end

  test "outbound order value producer net should report zero when inbound orders below order minimums 4" do
    #OM > 2 cases
    #this test has both an OM and uses cases. the OM < 1 case. play around at the limits and verify things are correct

    #specify posting values    
    @posting.update(order_minimum_producer_net: 25, units_per_case: 10, price: 1)

    #verify order submitted if inbound units ordered == 31
    #verify order not submitted if user removes quantity 2 such that inbound units ordered reduces to == 29

    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 29
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 29, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    #new users orders 2. total will now be 31 .
    u2 = create_user("u2", "u2@u.com")
    assert u2.valid?
    u2_ti1 = ToteItem.new(quantity: 2, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u2)    
    u2_ti1.save
    u2_ti1.transition(:customer_authorized)
    #verify order gets submitted now
    assert @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net > @posting.order_minimum_producer_net
    #u2 changes thier mind and cancels order
    u2_ti1.transition(:customer_removed)
    #verify order won't get submitted
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0

  end

  test "outbound order value producer net should report zero when inbound orders below order minimums 3" do
    #OM > 2 cases
    #this test has both an OM and uses cases. the OM < 1 case. play around at the limits and verify things are correct

    #specify posting values    
    @posting.update(order_minimum_producer_net: 25, units_per_case: 10, price: 1)

    #verify order submitted if inbound units ordered == 31

    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 29
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 29, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    #new users orders 2. total will now be 31 .
    u2 = create_user("u2", "u2@u.com")
    assert u2.valid?
    u2_ti1 = ToteItem.new(quantity: 2, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u2)    
    u2_ti1.save
    u2_ti1.transition(:customer_authorized)
    #verify order gets submitted now
    assert @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net > @posting.order_minimum_producer_net

  end

  test "outbound order value producer net should report zero when inbound orders below order minimums 2" do
    #OM > 2 cases
    #this test has both an OM and uses cases. the OM < 1 case. play around at the limits and verify things are correct

    #specify posting values    
    @posting.update(order_minimum_producer_net: 25, units_per_case: 10, price: 1)

    #verify order not submitted if inbound units ordered == 26

    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 26
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 26, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    
  end

  test "outbound order value producer net should report zero when inbound orders below order minimums" do
    #OM > 2 cases
    #this test has both an OM and uses cases. the OM < 1 case. play around at the limits and verify things are correct

    #specify posting values    
    @posting.update(order_minimum_producer_net: 25, units_per_case: 10, price: 1)

    #verify order not submitted if inbound units ordered == 24

    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 24
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 24, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    
  end
  
  test "outbound order value producer net should report zero when user removes item 3" do
    #OM < 1 case
    #this test has both an OM and uses cases. the OM < 1 case. play around at the limits and verify things are correct

    #specify posting values    
    @posting.update(order_minimum_producer_net: 5, units_per_case: 10, price: 1)

    #verify order not submitted if inbound units ordered == 9
    #verify order submitted if inbound units ordered == 11
    #verify order not submitted if user removes quantity 2 such that inbound units ordered returns to == 9

    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 9
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 9, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    #u2 orders 2
    u2 = create_user("u2", "u2@u.com")
    assert u2.valid?
    u2_ti1 = ToteItem.new(quantity: 2, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u2)        
    u2_ti1.save
    u2_ti1.transition(:customer_authorized)
    #verify order is submittable
    assert @posting.requirements_met_to_send_order?
    #verify outbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net > 0
    #verify that the outbound order amount equals 1 case, even though there were inbound orders totaling slightly more than one case
    assert_equal @posting.get_producer_net_case, @posting.outbound_order_value_producer_net
    #u2 cancels their order
    u2_ti1.transition(:customer_removed)    
    #verify outbound_order_value_producer_net == 0
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0

  end

  test "outbound order value producer net should report zero when user removes item 2" do

    #posting uses OM but not cases. initially orders total more than OM. then a user removes their item to bring inbound orders
    #to less than OM. verify the outbound order value is zero.

    #specify posting values    
    @posting.update(order_minimum_producer_net: 10, units_per_case: 1, price: 1)    
    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 9
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    #we are using 10 but this will create a inbound order value retail of 10. not producer net. so it should still cause 
    #us to be below OM
    u1_ti1 = ToteItem.new(quantity: 10, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.inbound_order_value_producer_net < 10
    assert @posting.inbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net == 0
    #u2 orders 2
    u2 = create_user("u2", "u2@u.com")
    assert u2.valid?
    u2_ti1 = ToteItem.new(quantity: 2, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u2)        
    u2_ti1.save
    u2_ti1.transition(:customer_authorized)
    #verify order is submittable
    assert @posting.requirements_met_to_send_order?
    assert @posting.inbound_order_value_producer_net > 10
    assert @posting.outbound_order_value_producer_net >= 10

    #u2 cancels their order
    u2_ti1.transition(:customer_removed)    
    #verify outbound order conditions unmet
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.inbound_order_value_producer_net < 10
    assert @posting.inbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net == 0

  end

  test "outbound order value producer net should report zero when user removes item" do

    #posting uses cases but no OM. initially orders total more than one case. then a user removes their item to bring inbound orders
    #to less than one case. verify the outbound order value is zero.

    #posting has upc = 10
    @posting.update(units_per_case: 10)
    assert_equal 10, @posting.units_per_case
    #posting has no OM
    assert_equal nil, @posting.order_minimum_producer_net
    #posting has no items
    assert_equal 0, @posting.tote_items.count
    #u1 orders 9
    u1 = create_user("u1", "u1@u.com")
    assert u1.valid?
    u1_ti1 = ToteItem.new(quantity: 9, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u1)    
    u1_ti1.save
    u1_ti1.transition(:customer_authorized)
    #verify minimums not met
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0
    #u2 orders 2
    u2 = create_user("u2", "u2@u.com")
    assert u2.valid?
    u2_ti1 = ToteItem.new(quantity: 2, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: u2)        
    u2_ti1.save
    u2_ti1.transition(:customer_authorized)
    #verify order is submittable
    assert @posting.requirements_met_to_send_order?
    #verify outbound_order_value_producer_net > 0
    assert @posting.outbound_order_value_producer_net > 0
    #verify that the outbound order amount equals 1 case, even though there were inbound orders totaling slightly more than one case
    assert_equal @posting.get_producer_net_case, @posting.outbound_order_value_producer_net
    #u2 cancels their order
    u2_ti1.transition(:customer_removed)    
    #verify outbound_order_value_producer_net == 0
    assert_not @posting.requirements_met_to_send_order?
    assert @posting.outbound_order_value_producer_net == 0

  end

  test "should submit order when posting value above order minimum" do
    @posting.update(order_minimum_producer_net: 100)
    ti = ToteItem.new(quantity: 100, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert @posting.requirements_met_to_send_order?    
  end
  
  test "should not submit order when posting value below order minimum" do
    @posting.update(order_minimum_producer_net: 100)
    ti = ToteItem.new(quantity: 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert_not @posting.requirements_met_to_send_order?    
  end

  test "posting should properly report remaining order amount necessary" do
    #the producer net order min is 100. this means the retail order min is > 100
    @posting.update(order_minimum_producer_net: 100)
    assert @posting.order_minimum_retail > @posting.order_minimum_producer_net
    ti = ToteItem.new(quantity: 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert_not @posting.requirements_met_to_send_order?    
    # $100 producer net order minimum equals ~$109 gross order min. a single unit worth gross $1.25 was ordered. so the amount it
    #sould report as needed additional is ~ $109 - $1.25
    assert_equal @posting.order_minimum_retail - @posting.price, @posting.additional_retail_amount_necessary_to_send_order
  end

  test "should not submit order when no quantity is authorized or committed" do
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save    
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:ADDED], @posting.tote_items.first.state
    assert_not @posting.requirements_met_to_send_order?
  end

  test "should submit order when quantity is above zero and cases arent in use" do
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert @posting.requirements_met_to_send_order?
  end

  test "should submit order when quantity is at least the size of a case" do
    case_size = 10
    @posting.units_per_case = case_size
    assert @posting.save
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: case_size + 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert @posting.requirements_met_to_send_order?
  end

  test "should only submit order in round case lots when applicable" do    
    case_size = 10
    @posting.units_per_case = case_size
    assert @posting.save
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: case_size + 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    
    assert_equal case_size, @posting.inbound_num_units_ordered
    assert_equal 1, @posting.inbound_num_cases_ordered
  end

  test "should submit order for all committed quantity when cases not in use" do
    unit_count = 11
    assert @posting.save
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: unit_count, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state    
    assert_equal unit_count, @posting.inbound_num_units_ordered
    assert_equal nil, @posting.inbound_num_cases_ordered
  end

  test "should not submit order when quantity authorized or committed is less than a case size" do
    case_size = 10
    @posting.units_per_case = case_size
    assert @posting.save
    assert_equal 0, @posting.tote_items.count
    ti = ToteItem.new(quantity: case_size - 1, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user: @user)
    assert ti.save
    ti.transition(:customer_authorized)
    ti.transition(:order_cutoffed)
    assert_equal 1, @posting.tote_items.count
    assert_equal ToteItem.states[:COMMITTED], @posting.tote_items.first.state
    assert_not @posting.requirements_met_to_send_order?
  end

  test "should fill all items" do
    num_items = 7
    quantity_per_item = 6
    quantity_received_from_producer = num_items * quantity_per_item
    fills_simulation(num_items, quantity_per_item, quantity_received_from_producer)
  end

  test "should partially fill last item" do
    num_items = 7
    quantity_per_item = 6
    quantity_received_from_producer = num_items * quantity_per_item - 2
    fills_simulation(num_items, quantity_per_item, quantity_received_from_producer)
  end

  test "should fill several items completely and then zero fill the last several items" do
    num_items = 7
    quantity_per_item = 6
    quantity_received_from_producer = (num_items - 3) * quantity_per_item
    fills_simulation(num_items, quantity_per_item, quantity_received_from_producer)
  end

  test "should fill several items partially fill one item and zero fill several items" do
    num_items = 7
    quantity_per_item = 6
    quantity_received_from_producer = (num_items / 2) * quantity_per_item + quantity_per_item / 2
    fills_simulation(num_items, quantity_per_item, quantity_received_from_producer)
  end

  def fills_simulation(num_items, quantity_per_item, quantity_received_from_producer)

    c1 = @user    
    assert_equal 0, c1.tote_items.joins(:posting).where("postings.id = ?", @posting.id).count

    num_items.times do      
      ti = ToteItem.new(quantity: quantity_per_item, posting_id: @posting.id, state: ToteItem.states[:ADDED], price: @posting.price, user_id: c1.id)      
      assert ti.save
      ti.transition(:customer_authorized)
      ti.transition(:order_cutoffed)
    end

    assert_equal num_items, c1.tote_items.joins(:posting).where("postings.id = ?", @posting.id).count

    travel_to @posting.order_cutoff
    RakeHelper.do_hourly_tasks

    @posting.fill(quantity_received_from_producer)

    c1_items = c1.tote_items.joins(:posting).where("postings.id = ?", @posting.id)

    count = 0
    quantity_remaining = quantity_received_from_producer

    c1_items.each do |tote_item|

      if quantity_remaining >= tote_item.quantity
        assert tote_item.fully_filled?
        assert_equal 1, tote_item.purchase_receivables.count
        assert tote_item.purchase_receivables.last.amount > 0
        assert_equal tote_item.purchase_receivables.last.amount, get_gross_item(tote_item, filled = true), "The PurchaseReceivable amount is #{tote_item.purchase_receivables.last.amount.to_s} but should be equal to the get_gross_item amount which is #{get_gross_item(tote_item).to_s}"
      elsif quantity_remaining > 0
        assert tote_item.partially_filled?
        assert_equal 1, tote_item.purchase_receivables.count
        assert tote_item.purchase_receivables.last.amount > 0
        assert tote_item.purchase_receivables.last.amount < get_gross_item(tote_item), "The PurchaseReceivable amount is #{tote_item.purchase_receivables.last.amount.to_s} but should be less than the get_gross_item amount which is #{get_gross_item(tote_item).to_s}"
      else
        assert tote_item.zero_filled?
        assert_equal 0, tote_item.purchase_receivables.count        
      end

      quantity_remaining -= tote_item.quantity_filled                  
      count += 1

    end

    assert num_items, count

    travel_back

  end

  test "should require varying additional units until user authorizes tote" do

    posting = postings(:postingf5apples)
    posting.update_attribute(:units_per_case, 10)

    c2 = users(:c2)
    ti = ToteItem.new(quantity: 5, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c2.id)    
    assert ti.save
    ti.transition(:customer_authorized)

    c1 = @user
    c1_ti1 = ToteItem.new(quantity: 2, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert c1_ti1.save    
    #c1_ti1.transition(:customer_authorized)

    #this is the additional quantity needed to fill the case.
    #takes in to account actually authorized items and all this user's ADDED items
    additional_units_required_to_fill_my_case = c1_ti1.additional_units_required_to_fill_my_case
    assert_equal 3, additional_units_required_to_fill_my_case

    #let's say that c1 doesn't auth 1st item but then ADDs a 2nd but again not quite enough to fill the case. this quantity 2 should 
    #be short 1 unit
    c1_ti2 = ToteItem.new(quantity: 2, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert c1_ti2.save

    #this is the additional quantity needed to fill the case.
    #takes in to account actually authorized items and all this user's ADDED items
    additional_units_required_to_fill_my_case = c1_ti2.additional_units_required_to_fill_my_case
    assert_equal 1, additional_units_required_to_fill_my_case

    #now let's say c2 adds 2 more units. 
    ti = ToteItem.new(quantity: 2, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c2.id)    
    assert ti.save

    #c2 then should see 3 more required.
    additional_units_required_to_fill_my_case = ti.additional_units_required_to_fill_my_case
    assert_equal 3, additional_units_required_to_fill_my_case

    #c1 should still see 1 more required.
    additional_units_required_to_fill_my_case = c1_ti2.additional_units_required_to_fill_my_case
    assert_equal 1, additional_units_required_to_fill_my_case

    #now lets say c2 authorizes these 2 additional units.
    ti.transition(:customer_authorized)

    #c2 should still see 3 remaining
    additional_units_required_to_fill_my_case = ti.additional_units_required_to_fill_my_case
    assert_equal 3, additional_units_required_to_fill_my_case

    #and now c1 should see 9 additional units remaining
    additional_units_required_to_fill_my_case = c1_ti2.additional_units_required_to_fill_my_case
    assert_equal 9, additional_units_required_to_fill_my_case

    #now c1 authorizes both items
    c1_ti1.transition(:customer_authorized)
    c1_ti2.transition(:customer_authorized)

    #now c1 should still see 9 additional units remaining
    additional_units_required_to_fill_my_case = c1_ti2.additional_units_required_to_fill_my_case
    assert_equal 9, additional_units_required_to_fill_my_case

    #c2 should now see 0 additional units remaining
    additional_units_required_to_fill_my_case = ti.additional_units_required_to_fill_my_case
    assert_equal 0, additional_units_required_to_fill_my_case

  end

  test "should require zero units to fill case when tote item far from end of queue" do
   
    posting = postings(:postingf5apples)
    posting.update_attribute(:units_per_case, 10)

    c2 = users(:c2)
    ti = ToteItem.new(quantity: 5, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c2.id)    
    assert ti.save
    ti.transition(:customer_authorized)

    c1 = @user
    c1_ti = ToteItem.new(quantity: 2, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert c1_ti.save    
    c1_ti.transition(:customer_authorized)

    ti_temp = ti
    
    5.times do
      ti_temp = ti
      ti = ToteItem.new(quantity: 6, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c2.id)      
      assert ti.save
      ti.transition(:customer_authorized)
    end
    
    total_quantity = posting.total_quantity_authorized_or_committed
    assert_equal 0, c1_ti.additional_units_required_to_fill_my_case

    #this is the very last item to get added. the total quantity ordered by all users is 37. we need to hit 40 to fill this last case.
    assert_equal 3, ti.additional_units_required_to_fill_my_case
    #this is the 2nd to last item. it's up-through quantity should be 31. the item after this (the .last item) has quantity 6 so
    #it's up-through quantity should be 37 so both these items should have 'units_required' of 3 to get the case filled
    assert_equal 3, ti_temp.additional_units_required_to_fill_my_case

  end

  test "total_quantity_authorized_or_committed should be correct" do
    posting = postings(:p5)

    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6}

    posting.tote_items[0].state = ToteItem.states[:ADDED]
    posting.tote_items[1].state = ToteItem.states[:AUTHORIZED]
    posting.tote_items[2].state = ToteItem.states[:COMMITTED]
    posting.tote_items[4].state = ToteItem.states[:FILLED]
    posting.tote_items[5].state = ToteItem.states[:NOTFILLED]
    posting.tote_items[6].state = ToteItem.states[:REMOVED]

    posting.tote_items[0].save
    posting.tote_items[1].save
    posting.tote_items[2].save
    posting.tote_items[3].save
    posting.tote_items[4].save
    posting.tote_items[5].save
    posting.tote_items[6].save
    posting.tote_items[7].save

    assert_equal 4, posting.total_quantity_authorized_or_committed

  end

  test "total_quantity_ordered should be correct" do
    posting = postings(:p5)

    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASED: 8, PURCHASEFAILED: 9}
    posting.tote_items[0].state = ToteItem.states[:ADDED]
    posting.tote_items[1].state = ToteItem.states[:AUTHORIZED]
    posting.tote_items[2].state = ToteItem.states[:COMMITTED]
    posting.tote_items[4].state = ToteItem.states[:FILLED]
    posting.tote_items[5].state = ToteItem.states[:NOTFILLED]
    posting.tote_items[6].state = ToteItem.states[:REMOVED]

    posting.tote_items[0].save
    posting.tote_items[1].save
    posting.tote_items[2].save
    posting.tote_items[4].save
    posting.tote_items[5].save
    posting.tote_items[6].save

    assert_equal 8, posting.total_quantity_ordered

  end

  test "posting is valid" do    
    assert @posting.valid?, get_error_messages(@posting)
  end

  test "description must be present" do
    @posting.description = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "price must be present and positive" do
    @posting.price = nil
    assert_not @posting.valid?, get_error_messages(@posting)    
    @posting.price = -1
    assert_not @posting.valid?, get_error_messages(@posting)    
    @posting.price = 1.25
    assert @posting.valid?, get_error_messages(@posting)    
  end

  test "delivery_date must be present" do
    @posting.delivery_date = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "delivery_date must not be sunday" do
    while !@posting.delivery_date.sunday?
      @posting.delivery_date += 1.day
    end
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should not be created with past delivery date" do
    
    delivery_date = Time.zone.tomorrow.midnight
    if delivery_date.sunday?
      delivery_date += 3.days
    end

    posting = Posting.new(
      delivery_date: delivery_date,
      order_cutoff: delivery_date - 1.day,
      product: @product,
      price: 10,
      user: @farmer,
      unit: @unit,
      description: "crisp, crunchy organic apples. you'll love them.",
      live: true
      )

    #as the object is now it could be created
    assert posting.valid?

    #but now let's make and assign an invalid delivery date...a date in the past

    new_delivery_date = Time.zone.now.midnight - 1.day
    if new_delivery_date.sunday?
      new_delivery_date -= 1.days
    end

    posting.delivery_date = new_delivery_date

    #now this save should not work because the delivery date is in the past
    assert_not posting.save
    assert_not posting.id    

  end

  test "posting should be updatable with past delivery date" do

    delivery_date = Time.zone.tomorrow.midnight
    if delivery_date.sunday?
      delivery_date += 3.days
    end

    posting = Posting.new(
      delivery_date: delivery_date,
      order_cutoff: delivery_date - 1.day,
      product: @product,
      price: 10,
      user: @farmer,
      unit: @unit,
      description: "crisp, crunchy organic apples. you'll love them.",
      live: true
      )

    #as the object is now it could be created
    assert posting.valid?
    assert posting.save
    assert posting.id > 0

    #now let's travel to the future, such that the delivery date will be in the past
    travel_to posting.delivery_date + 3.days

    #now let's update a value
    assert posting.update(state: 0)
    posting.reload
    assert_equal 0, posting.state

    assert posting.update(state: 1)
    posting.reload
    assert_equal 1, posting.state

    travel_back

  end

  test "posting should have user" do
    @posting.user_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should have product" do
    @posting.product_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should have unit" do
    @posting.unit_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "commitment zone must be present" do
    @posting.order_cutoff = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

end