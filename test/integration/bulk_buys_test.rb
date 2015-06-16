require 'test_helper'
require 'bulk_buy_helper'

class BulkBuysTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end

  test "bulk buy should get created and saved to database" do
    create_bulk_buy
  end
end
