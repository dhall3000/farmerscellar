require 'test_helper'

class ToteItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@tote_item = tote_items(:c1apple)

    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.sunday?
      delivery_date = Time.zone.today + 4.days
    end

    @posting = Posting.new(units_per_case: 10, unit: @unit, product: @product, user: @farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: delivery_date - 2.days, delivery_date: delivery_date)
    @posting.save
  end

  test "should tell user first added item will ship but second added item will not ship" do
    #user auths 3 of a 10-unit-case posting. then c1 adds 3 so that 4 more are needed then c1 adds 5 so that his first item should get
    #shipped if he authorizes but the second item should report 9 more needed to ship.    
    assert_equal 0, @posting.tote_items.count

    c4 = users(:c4)
    ti = create_tote_item(c4, @posting, 3, authorize = true)
    assert_equal 7, ti.additional_units_required_to_fill_my_case
    
    c1 = users(:c1)
    ti3 = create_tote_item(c1, @posting, 3, authorize = false)
    assert_equal 4, ti3.additional_units_required_to_fill_my_case

    ti5 = create_tote_item(c1, @posting, 5, authorize = false)
    assert_equal 9, ti5.additional_units_required_to_fill_my_case

    #if the user auth'd right now ti3 should fully fill. only ti5 should partially fill
    assert_equal 0, ti3.additional_units_required_to_fill_my_case
    
  end

  def create_tote_item(user, posting, quantity, authorize = false)
    
    tote_item = ToteItem.new(quantity: quantity, posting: posting, user: user, price: posting.price)
    assert tote_item.valid?
    assert tote_item.save

    if authorize
      tote_item.transition(:customer_authorized)
      tote_item.reload
      assert tote_item.state?(:AUTHORIZED)
    end

    return tote_item

  end

  test "users first item should be shippable but not the second" do
    #make a test where anonymouse user auths 3 of a 10-unit-case posting. then c1 adds 3 so that 4 more are needed then c1 adds 5 so that his first item should
    #get shipped if he authorizes but the second item should report 9 more needed to ship.
    c2 = users(:c2)
    tic2 = create_tote_item(c2, @posting, quantity = 3, authorize = true)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case

    c1 = users(:c1)
    tic1_1 = create_tote_item(c1, @posting, quantity = 3, authorize = false)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case
    assert_equal 4, tic1_1.additional_units_required_to_fill_my_case  

    tic1_2 = create_tote_item(c1, @posting, quantity = 5, authorize = false)
    assert_equal 7, tic2.additional_units_required_to_fill_my_case
    assert_equal 0, tic1_1.additional_units_required_to_fill_my_case  
    assert_equal 9, tic1_2.additional_units_required_to_fill_my_case  

  end

  test "should say authorized item will ship but added item will not ship" do
    #what happens if user auths an item, then that case fully fills with others' auth'd items. then user comes and adds another item such that
    #this last item's case isn't filled. will it say that the user's original auth'd item comes up short?

    c1 = users(:c1)
    ti1 = create_tote_item(c1, @posting, quantity = 3, authorize = true)
    assert_equal 7, ti1.additional_units_required_to_fill_my_case

    c4 = users(:c4)
    ti2 = create_tote_item(c4, @posting, quantity = 7, authorize = true)
    assert_equal 0, ti1.additional_units_required_to_fill_my_case
    assert_equal 0, ti2.additional_units_required_to_fill_my_case    

    ti3 = create_tote_item(c1, @posting, quantity = 2, authorize = false)
    assert_equal 0, ti1.additional_units_required_to_fill_my_case
    assert_equal 0, ti2.additional_units_required_to_fill_my_case
    assert_equal 8, ti3.additional_units_required_to_fill_my_case

  end

  test "should partially fill" do

    assert_equal 0, @tote_item.purchase_receivables.count

    assert_equal ToteItem.states[:ADDED], @tote_item.state
    @tote_item.transition(:customer_authorized)
    @tote_item.transition(:commitment_zone_started)
    @tote_item.transition(:tote_item_filled, {quantity_filled: @tote_item.quantity / 2})

    @tote_item.reload
    assert_equal ToteItem.states[:FILLED], @tote_item.state
    assert @tote_item.quantity_filled < @tote_item.quantity
    assert_equal @tote_item.quantity / 2, @tote_item.quantity_filled

    assert_equal 1, @tote_item.purchase_receivables.count
    assert @tote_item.purchase_receivables.last.amount > 0
    assert @tote_item.purchase_receivables.last.amount < get_gross_item(@tote_item), "The PurchaseReceivable amount is #{@tote_item.purchase_receivables.last.amount.to_s} but should be less than the get_gross_item amount which is #{get_gross_item(@tote_item).to_s}"

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
    @tote_item.transition(:commitment_zone_started)    
    @tote_item.reload
    @tote_item.transition(:tote_item_filled, {quantity_filled: @tote_item.quantity})
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
  	@tote_item.state = 0
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
    @tote_item.state = 9
    #NOTE: this assert_not is accidentally brilliant. leaving this here will ensure that down the road no dev
    #wanting to add a new state to ToteItem class will use the value '9'. Using 9 would be bad because, since it
    #was once upon a time used, there will be 9's in the production database so if you (Mr. Dev, whoever you are),
    #in the future use 9 again, your logic will work great in dev but break in production    
    assert_not @tote_item.valid?

  	@tote_item.state = -1
  	assert_not @tote_item.valid?
  	@tote_item.state = 12
  	assert_not @tote_item.valid?
  end

end
