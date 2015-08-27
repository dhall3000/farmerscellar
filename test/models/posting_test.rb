require 'test_helper'

class PostingTest < ActiveSupport::TestCase

  def setup
    @posting = Posting.new(quantity_available: 100, price: 1.25, live: true)
  end

  test "posting is valid" do
    assert @posting.valid?
  end

  test "quantity must be positive" do
  	@posting.quantity_available = 0
  	assert_not @posting.valid?
  end

  test "live must be present" do
  	@posting.live = nil
  	assert_not @posting.valid?
  end  

end
