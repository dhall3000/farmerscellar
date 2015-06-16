require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end

  test "do bulk buy" do
  	create_bulk_buy
  end
end
