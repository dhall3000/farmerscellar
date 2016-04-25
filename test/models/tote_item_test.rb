require 'test_helper'

class ToteItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@tote_item = tote_items(:c1apple)
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
    ToteItem.all.update_all(state: ToteItem.states[:AUTHORIZED])
    #move delivery date to 1 day before one of the posting delivery dates
    travel_to ToteItem.first.posting.delivery_date - 1.day
    #verify that some users have delivery later this week
    users = ToteItem.get_users_with_no_deliveries_later_this_week
    assert users.count < User.count

    travel_back    

  end

  test "should create purchase receivable object" do
    pr_count = PurchaseReceivable.count
    @tote_item.update(state: ToteItem.states[:COMMITTED])
    @tote_item.reload
    @tote_item.transition(:tote_item_filled)
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
    @tote_item.update(state: ToteItem.states[:AUTHORIZED])
    @tote_item.save
    ti = @tote_item.reload
    assert_equal ToteItem.states[:AUTHORIZED], @tote_item.state
    ti.deauthorize
    ti = @tote_item.reload
    assert_equal ToteItem.states[:ADDED], @tote_item.state
  end

  test "should not deauthorize" do
    @tote_item.state = ToteItem.states[:COMMITTED]
    assert @tote_item.state?(:COMMITTED)    
    @tote_item.deauthorize
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
