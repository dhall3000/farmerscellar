require 'test_helper'

class PostingTest < ActiveSupport::TestCase

  def setup
    user = users(:c1)
    product = products(:apples)
    unit_kind = unit_kinds(:pound)
    unit_category = unit_categories(:weight)
    @posting = Posting.new(unit_category: unit_category, unit_kind: unit_kind, product: product, user: user, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.today + 2.days, delivery_date: Time.zone.today + 3.days)
    @posting.save
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

  test "posting should have user" do
    @posting.user_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should have product" do
    @posting.product_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should have unit category" do
    @posting.unit_category_id = nil
    assert_not @posting.valid?, get_error_messages(@posting)
  end

  test "posting should have unit kind" do
    @posting.unit_kind_id = nil
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
