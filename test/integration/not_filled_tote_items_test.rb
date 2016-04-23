require 'test_helper'
require 'bulk_buy_helper'

class NotFilledToteItemsTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end
  test "not all tote items get filled" do
    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c_one_tote_item, @c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)

    assert ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count > 0
    assert_equal 0, ToteItem.where(state: ToteItem.states[:COMMITTED]).count
    assert_equal 0, ToteItem.where(state: ToteItem.states[:FILLED]).count
    assert_equal 0, ToteItem.where(state: ToteItem.states[:FILLPENDING]).count

    transition_authorized_tote_items_to_committed(customers)
    fill_all_tote_items = false
    time_travel_to_delivery_dates = true
    simulate_order_filling(fill_all_tote_items, time_travel_to_delivery_dates)

    assert_equal 0, ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count    
    assert_equal 0, ToteItem.where(state: ToteItem.states[:COMMITTED]).count
    assert_equal 0, ToteItem.where(state: ToteItem.states[:FILLPENDING]).count

    num_tote_items = ToteItem.where(user_id: customers).count
    num_filled = ToteItem.where(state: ToteItem.states[:FILLED]).count
    num_not_filled = ToteItem.where(state: ToteItem.states[:NOTFILLED]).count
    assert num_not_filled > 0
    assert_equal num_tote_items, num_filled + num_not_filled

  end

end
