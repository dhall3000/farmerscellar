require 'model_test_ancestor'

class AuthorizationTest < ModelTestAncestor
  # test "the truth" do
  #   assert true
  # end
  def setup    

    t8 = tote_items(:t8)
    t8.update(state: ToteItem.states[:AUTHORIZED])
    t9 = tote_items(:t9)
    t9.update(state: ToteItem.states[:AUTHORIZED])
    t10 = tote_items(:t10)
    t10.update(state: ToteItem.states[:AUTHORIZED])

    @checkout = checkouts(:checkout1)
    @checkout.tote_items << t8
    @checkout.tote_items << t9
    @checkout.tote_items << t10
    @checkout.save

    @authorization = Authorization.new(token: "faketoken", payer_id: "ED-127", amount: 22.75, correlation_id: "correlationid", transaction_id: "transactionid", payment_date: Date.today, gross_amount: 22.75, response: "responsetext", ack: "ackstring")
    @authorization2 = Authorization.new(token: "faketoken", payer_id: "ED-127", amount: 22.75, correlation_id: "correlationid", transaction_id: "transactionid", payment_date: Date.today, gross_amount: 22.75, response: "responsetext", ack: "ackstring")

  end

  test "should return all authorized tote items" do
    assert_not @authorization.checkouts.any?
    assert_equal 0, @authorization.tote_items.count
    @authorization.checkouts << @checkout
    assert @authorization.save
    tote_items = @authorization.tote_items
    assert_equal 3, tote_items.count
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
