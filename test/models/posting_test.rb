require 'test_helper'

class PostingTest < ActiveSupport::TestCase

  def setup
    user = users(:c1)
    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)

    delivery_date = Time.zone.today + 3.days

    if delivery_date.sunday?
      delivery_date = Time.zone.today + 4.days
    end

    @posting = Posting.new(unit: @unit, product: @product, user: user, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: delivery_date - 2.days, delivery_date: delivery_date)
    @posting.save
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
