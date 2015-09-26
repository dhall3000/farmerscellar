require 'test_helper'
require 'bulk_buy_helper'

class NotFilledToteItemsTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end
  test "not all tote items get filled" do
    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)

    assert ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count > 0
    assert_equal 0, ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    assert_equal 0, ToteItem.where(status: ToteItem.states[:FILLED]).count
    assert_equal 0, ToteItem.where(status: ToteItem.states[:FILLPENDING]).count

    transition_authorized_tote_items_to_committed
    fill_all_tote_items = false
    simulate_order_filling(fill_all_tote_items)

    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count    
    assert_equal 0, ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    assert_equal 0, ToteItem.where(status: ToteItem.states[:FILLPENDING]).count

    num_tote_items = ToteItem.all.count
    num_filled = ToteItem.where(status: ToteItem.states[:FILLED]).count
    num_not_filled = ToteItem.where(status: ToteItem.states[:NOTFILLED]).count
    assert_equal num_tote_items, num_filled + num_not_filled

  end

end
