require 'test_helper'

class ToteItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@tote_item = tote_items(:c1apple)
  end

  test "state checker" do
    assert @tote_item.state?(:ADDED)
    @tote_item.status = ToteItem.states[:AUTHORIZED]
    assert @tote_item.state?(:AUTHORIZED)    
  end

  test "should deauthorize" do
    @tote_item.update(status: ToteItem.states[:AUTHORIZED])
    @tote_item.save
    ti = @tote_item.reload
    assert_equal ToteItem.states[:AUTHORIZED], @tote_item.status
    ti.deauthorize
    ti = @tote_item.reload
    assert_equal ToteItem.states[:ADDED], @tote_item.status
  end

  test "should not deauthorize" do
    @tote_item.status = ToteItem.states[:COMMITTED]
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
    @tote_item.status = 9
    assert @tote_item.valid?

  	@tote_item.status = -1
  	assert_not @tote_item.valid?
  	@tote_item.status = 10
  	assert_not @tote_item.valid?
  end

end
