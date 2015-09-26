require 'test_helper'
require 'bulk_buy_helper'

class BulkBuysTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end

  test "bulk buy should get created and saved to database" do
  	fill_all_tote_items = true
    create_bulk_buy(fill_all_tote_items)
  end
end
