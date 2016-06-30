require 'test_helper'

class PostingTest < ActiveSupport::TestCase

  def setup
    @user = users(:c1)
    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.sunday?
      delivery_date = Time.zone.today + 4.days
    end

    @posting = Posting.new(unit: @unit, product: @product, user: @farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: delivery_date - 2.days, delivery_date: delivery_date)
    @posting.save
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

    #this is the quantity actually authorized plus c1's ADDED item
    queue_quantity_through_item = posting.queue_quantity_through_item_plus_users_added_items(c1_ti1)    
    assert_equal 7, queue_quantity_through_item

    #this is the additional quantity needed to fill the case.
    #takes in to account actually authorized items and all this user's ADDED items
    additional_units_required_to_fill_my_case = c1_ti1.additional_units_required_to_fill_my_case
    assert_equal 3, additional_units_required_to_fill_my_case

    #let's say that c1 doesn't auth 1st item but then ADDs a 2nd but again not quite enough to fill the case. this quantity 2 should 
    #be short 1 unit
    c1_ti2 = ToteItem.new(quantity: 2, posting_id: posting.id, state: ToteItem.states[:ADDED], price: posting.price, user_id: c1.id)    
    assert c1_ti2.save

    #this is the quantity actually authorized which should exclude c1's ADDED items
    queue_quantity_through_item = posting.queue_quantity_through_item_plus_users_added_items(c1_ti2)    
    assert_equal 9, queue_quantity_through_item

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
    queue_quantity_through_item = posting.queue_quantity_through_item_plus_users_added_items(c1_ti)

    assert_equal 7, queue_quantity_through_item
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

  test "quantity_available must be present and positive" do
    @posting.quantity_available = nil
    assert_not @posting.valid?, get_error_messages(@posting)
    @posting.quantity_available = -1
    assert_not @posting.valid?, get_error_messages(@posting)
    @posting.quantity_available = 0
    assert_not @posting.valid?, get_error_messages(@posting)
    @posting.quantity_available = 1
    assert @posting.valid?, get_error_messages(@posting)
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
      commitment_zone_start: delivery_date - 1.day,
      product: @product,
      quantity_available: 100,
      price: 10,
      user: @farmer,
      unit: @unit,
      description: "crisp, crunchy organic apples. you'll love them.",
      live: true,
      late_adds_allowed: false
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
      commitment_zone_start: delivery_date - 1.day,
      product: @product,
      quantity_available: 100,
      price: 10,
      user: @farmer,
      unit: @unit,
      description: "crisp, crunchy organic apples. you'll love them.",
      live: true,
      late_adds_allowed: false
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
    @posting.commitment_zone_start = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "live must be present" do
  	@posting.live = nil
  	assert_not @posting.valid?, get_error_messages(@posting)
  end  

end
