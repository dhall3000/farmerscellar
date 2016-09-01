require 'test_helper'

class BulkPaymentsControllerTest < ActionDispatch::IntegrationTest

  def setup
  	@a1 = users(:a1)
  end

  test "should get new" do
  	log_in_as(@a1)
    get new_bulk_payment_path
    assert_response :success
  end

  test "should redirect on get new" do
    get new_bulk_payment_path
    assert_response :redirect
  end

  test "should redirect on get create" do
    post bulk_payments_path
    assert_response :redirect
  end

  test "should get create" do
  	log_in_as(@a1)
  	post bulk_payments_path
  	assert_response :success
  end

end
