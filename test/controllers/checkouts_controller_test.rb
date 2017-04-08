require 'integration_helper'

class CheckoutsControllerTest < IntegrationHelper
  
  def setup
  	@c1 = users(:c1)
  end

  test "should create one time checkout" do
  	log_in_as(@c1)
  	checkouts_count = Checkout.count
  	post checkouts_path, params: {use_reference_transaction: 0}
  	assert_nil flash[:danger]
  	assert_equal checkouts_count + 1, Checkout.count
  	assert_equal false, Checkout.last.is_rt
  end

  test "should create reference transaction checkout" do
  	log_in_as(@c1)
  	checkouts_count = Checkout.count
  	post checkouts_path, params: {use_reference_transaction: 1}
  	assert_nil flash[:danger]
  	assert_equal checkouts_count + 1, Checkout.count
  	assert_equal true, Checkout.last.is_rt
  end

end