require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  def setup    
    @checkout = checkouts(:checkout1)
    @authorization = Authorization.new(token: "faketoken", payer_id: "ED-127", amount: 22.75, correlation_id: "correlationid", transaction_id: "transactionid", payment_date: Date.today, gross_amount: 22.75, response: "responsetext", ack: "ackstring")
    @authorization2 = Authorization.new(token: "faketoken", payer_id: "ED-127", amount: 22.75, correlation_id: "correlationid", transaction_id: "transactionid", payment_date: Date.today, gross_amount: 22.75, response: "responsetext", ack: "ackstring")
  end

  test "authorization should save" do
    @authorization.checkouts << @checkout
    assert @authorization.save
  end

  test "authorization should not save without associated checkout object" do
    assert_not @authorization.save    
  end

  test "should not save without token" do    
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.token = nil
    assert_not @authorization2.save
  end

  test "should not save without payer_id" do
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.payer_id = nil
    assert_not @authorization2.save
  end

  test "should not save without amount" do
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.amount = nil
    assert_not @authorization2.save
  end

  test "should not save without correlation_id" do    
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.correlation_id = nil
    assert_not @authorization2.save
  end

  test "should not save without transaction_id" do  	
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.transaction_id = nil
    assert_not @authorization2.save
  end

  test "should not save without payment_date" do    
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.payment_date = nil
    assert_not @authorization2.save
  end

  test "should not save without gross_amount" do
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.gross_amount = nil
    assert_not @authorization2.save
  end

  test "should not save without response" do    
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.response = nil
    assert_not @authorization2.save
  end

  test "should not save without ack" do    
    @authorization.checkouts << @checkout
    assert @authorization.save
    @authorization2.checkouts << @checkout
    @authorization2.ack = nil
    assert_not @authorization2.save
  end

end
