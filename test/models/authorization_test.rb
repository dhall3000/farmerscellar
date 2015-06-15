require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should not save without token" do
  	authorization = Authorization.new  	
  	authorization.payer_id = "fakepayerid"
  	authorization.amount = "fakeamount"
  	authorization.transaction_id = "faketransactionid"
  	authorization.gross_amount = "fakegrossamount"
  	assert_not authorization.save, "saved authorization without valid token"
  end

  test "should not save without payer_id" do
  	authorization = Authorization.new
  	authorization.token = "faketoken"  	
  	authorization.amount = "fakeamount"
  	authorization.transaction_id = "faketransactionid"
  	authorization.gross_amount = "fakegrossamount"
  	assert_not authorization.save, "saved authorization without valid payer_id"
  end

  test "should not save without amount" do
  	authorization = Authorization.new
  	authorization.token = "faketoken"
  	authorization.payer_id = "fakepayerid"  	
  	authorization.transaction_id = "faketransactionid"
  	authorization.gross_amount = "fakegrossamount"
  	assert_not authorization.save, "saved authorization without valid amount"
  end

  test "should not save without transaction_id" do  	
  	authorization = Authorization.new
  	authorization.token = "faketoken"
  	authorization.payer_id = "fakepayerid"
  	authorization.amount = "fakeamount"  	
  	authorization.gross_amount = "fakegrossamount"
  	assert_not authorization.save, "saved authorization without valid transaction_id"
  end

  test "should not save without gross_amount" do
  	authorization = Authorization.new
 	authorization.token = "faketoken"
  	authorization.payer_id = "fakepayerid"
  	authorization.amount = "fakeamount"
  	authorization.transaction_id = "faketransactionid"  	
  	assert_not authorization.save, "saved authorization without valid gross_amount"
  end

end
