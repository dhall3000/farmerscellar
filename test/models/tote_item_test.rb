require 'test_helper'

class ToteItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@tote_item = tote_items(:c1apple)
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

  test "status should be present" do
  	@tote_item.status = nil
  	assert_not @tote_item.valid?
  end

  test "status should be integer" do
  	@tote_item.status = 1.5
  	assert_not @tote_item.valid?
  end

  test "status should be within range" do
  	@tote_item.status = 0
  	assert @tote_item.valid?
  	@tote_item.status = 1
  	assert @tote_item.valid?
  	@tote_item.status = 2
  	assert @tote_item.valid?
  	@tote_item.status = 3
  	assert @tote_item.valid?
  	@tote_item.status = 4
  	assert @tote_item.valid?
  	@tote_item.status = 5
  	assert @tote_item.valid?
  	@tote_item.status = 6
  	assert @tote_item.valid?
  	@tote_item.status = 7
  	assert @tote_item.valid?
  	@tote_item.status = 8
  	assert @tote_item.valid?

  	@tote_item.status = -1
  	assert_not @tote_item.valid?
  	@tote_item.status = 9
  	assert_not @tote_item.valid?
  end

end
