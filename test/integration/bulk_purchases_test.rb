require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer

  #bundle exec rake test test/integration/bulk_purchases_test.rb test_do_bulk_buy
  test "do bulk buy" do
  #def skip
    customers = [@c1, @c2, @c3, @c4]
    purchase_receivables = setup_bulk_purchase(customers)
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase

    verify_proper_number_of_payment_payables
    bulk_purchase = assigns(:bulk_purchase)

    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id
    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id
    bulk_payment = assigns(:bulk_payment)

    assert_equal bulk_purchase.total_net, bulk_payment.total_payments_amount    

    get new_delivery_path
    assert :success
    assert_template 'deliveries/new'
    delivery_eligible_postings = assigns(:delivery_eligible_postings)
    dropsites = assigns(:dropsites)
    assert delivery_eligible_postings.count > 0
    assert dropsites.count > 0

    delivery_count = Delivery.count
    ids = []
    delivery_eligible_postings.each do |posting|
      ids << posting.id
    end

    post deliveries_path, posting_ids: ids
    delivery = assigns(:delivery)
    assert_redirected_to delivery_path(delivery)
    follow_redirect!
    assert_template 'deliveries/show'
    assert_not flash.empty?
    assert_select 'a', "Edit Delivery"
    get edit_delivery_path(delivery)
    assert_template 'deliveries/edit'
    dropsites_deliverable = assigns(:dropsites_deliverable)


    dropsites_deliverable.each do |dropsite|
      patch delivery_path(delivery), dropsite_id: dropsite.id
    end

  end

  def verify_proper_account_states(customers)
    
    customers.each do |customer|
      verify_proper_account_state(customer)
    end

  end

  def verify_proper_account_state(customer)
    
    account_ok = customer.user_account_states.order(:created_at).last.account_state.state == AccountState.states[:OK]

    #verify shopping tote empty. this actually technically doesn't have to be the case for customers with good standing
    #but it is now true given the way the test is written
    assert_equal ToteItem.where(status: ToteItem.states[:ADDED], user_id: customer.id).count, 0
    assert_equal ToteItem.where(status: ToteItem.states[:AUTHORIZED], user_id: customer.id).count, 0
    assert_equal ToteItem.where(status: ToteItem.states[:COMMITTED], user_id: customer.id).count, 0

    posting_lettuce = postings(:postingf1lettuce)
    log_in_as(customer)   

    #try to pull up the buy form for a particular posting
    get new_tote_item_path(posting_id: posting_lettuce.id)

    #check for the existence of nasty-gram related to account state
    if account_ok
      assert_select 'p', false, "Your account is on hold, most likely due to a positive balance on your account. Please contact Farmer's Cellar to pay your balance before continuing to shop."
    else
      assert_select 'p', "Your account is on hold, most likely due to a positive balance on your account. Please contact Farmer's Cellar to pay your balance before continuing to shop."
    end    

    #verify can't add new tote items
    
  end

  #bundle exec rake test test/integration/bulk_purchases_test.rb
  test "do bulk buy with purchase failures" do
  #def skip1
    customers = [@c1, @c2, @c3, @c4]
    purchase_receivables = setup_bulk_purchase(customers)

    #COMMENT KEY 000: we're going to set up c1 so that he has some toteitems in a bulk purchase that fail but at the moment of fail
    #he also has a ti that's ADDED and another that's AUTHORIZED. the code should sense these latter two and
    #switch them to state REMOVED. so we're going to first verify that we have zero in the REMOVED state and
    #then after the purchase failure verify that we have 2 in the REMOVED state
    assert_equal ToteItem.where(status: ToteItem.states[:REMOVED]).count, 0

    #authorize some more tote items
    log_in_as(@c1)
    posting_lettuce = postings(:postingf1lettuce)
    post tote_items_path, tote_item: {quantity: 2, price: posting_lettuce.price, status: ToteItem.states[:ADDED], posting_id: posting_lettuce.id, user_id: @c1.id}
    get tote_items_path
    total_amount_to_authorize = assigns(:total_amount_to_authorize)    
    post checkouts_path, amount: total_amount_to_authorize
    follow_redirect!
    authorization = assigns(:authorization)
    post authorizations_path, authorization: {token: authorization.token, payer_id: authorization.payer_id, amount: authorization.amount}
    authorization = assigns(:authorization)    

    #add some more toteitems    
    posting_tomato = postings(:postingf2tomato)
    post tote_items_path, tote_item: {quantity: 2, price: posting_tomato.price, status: ToteItem.states[:ADDED], posting_id: posting_tomato.id, user_id: @c1.id}

    #by the time we get to this point c1 should have 10 toteitems, 8 in PURCHASEPENDING, 1 in ADDED and 1 in AUTHORIZED

    log_in_as(@a1)
    FakeCaptureResponse.toggle_success = true    
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    
    #COMMENT KEY 000
    assert_equal ToteItem.where(status: ToteItem.states[:REMOVED]).count, 2
    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables    
    bulk_purchase = assigns(:bulk_purchase)

    verify_proper_account_states(customers)
    log_in_as(@a1)

    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id
    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id
    bulk_payment = assigns(:bulk_payment)

    assert_equal bulk_purchase.total_net, bulk_payment.total_payments_amount    
  end

  test "sequential bulk buys with some purchase failures" do

    FakeCaptureResponse.toggle_success = true    
    customers = [@c1, @c2]

    purchase_receivables = setup_bulk_purchase(customers)    
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables    
    bulk_purchase = assigns(:bulk_purchase)    
    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id
    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id
    bulk_payment = assigns(:bulk_payment)
    assert_equal bulk_purchase.total_net, bulk_payment.total_payments_amount

    FakeCaptureResponse.toggle_success = false    
    FakeCaptureResponse.succeed = true
    customers = [@c3, @c4]

    purchase_receivables = setup_bulk_purchase(customers)    
    num_prs_just_created = purchase_receivables.count
    post bulk_purchases_path, purchase_receivables: purchase_receivables    

    #here we want to verify that this bulk purchase is not picking up any failed purchasereceivables from
    #the prior bulk purchase
    bulk_purchase = assigns(:bulk_purchase)
    assert_equal num_prs_just_created, bulk_purchase.purchase_receivables.count

    verify_legitimacy_of_bulk_purchase    
    verify_proper_number_of_payment_payables    
    bulk_purchase = assigns(:bulk_purchase)    
    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id
    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id
    bulk_payment = assigns(:bulk_payment)
    assert_equal bulk_purchase.total_net, bulk_payment.total_payments_amount

  end

  def verify_legitimacy_of_bulk_purchase
    assert :success
    assert_template 'bulk_purchases/create'
    purchase_receivables = assigns(:purchase_receivables)    
    bulk_purchase = assigns(:bulk_purchase)
    assert_not_nil bulk_purchase

    prs = bulk_purchase.purchase_receivables

    total_amount_paid = 0
    for pr in prs
      #NOTE!! it looks like i've done a good job to date of avoiding putting .round(2) in the test code anywhere. but
      #i came across a failure where it really seems like it's the summing of the total_amount_paid var that is
      #causing the funky values. I was able to duplicte this in a terminal like this:
      #irb(main):007:0> amount = 150.91 + 91.0+100.5+82.0
      #=> 424.40999999999997
      total_amount_paid = (total_amount_paid + pr.amount_purchased).round(2)
    end
    
    #verify sum of pr amountpaids == bulkpurchase.totalgross
    assert_equal total_amount_paid, bulk_purchase.total_gross
    all_purchases_succeeded = all_purchase_receivables_succeeded(prs)

    #verify the associated bulkbuy's amount is proper relative to the bulkpurchase's totalgross
    if all_purchases_succeeded
      assert_equal purchase_receivables.last.bulk_buys.last.amount, bulk_purchase.total_gross      
    else
      #if there are failed purchases we would expect the actual amount collected to be less than the bulk buy anticipated amount
      assert purchase_receivables.last.bulk_buys.last.amount > bulk_purchase.total_gross
    end

      #NOTE!! it looks like i've done a good job to date of avoiding putting .round(2) in the test code anywhere. but
      #i came across a failure where it really seems like it's the summing of the total_amount_paid var that is
      #causing the funky values. I was able to duplicte this in a terminal like this:
      #irb(main):008:0> amount = 14.87+32.66+376.89
      #=> 424.41999999999996
    assert_equal bulk_purchase.total_gross, (bulk_purchase.total_fee.round(2) + bulk_purchase.total_commission.round(2) + bulk_purchase.total_net.round(2)).round(2)
    assert bulk_purchase.total_gross > 0
    assert bulk_purchase.total_fee > 0
    assert bulk_purchase.total_commission > 0
    assert bulk_purchase.total_net > 0
    assert bulk_purchase.total_gross > bulk_purchase.total_net
    assert bulk_purchase.total_net > bulk_purchase.total_commission
    assert bulk_purchase.total_commission > bulk_purchase.total_fee
    verify_legitimacy_of_purchase_receivables
  end

  def verify_legitimacy_of_purchase_receivables
    prs = assigns(:purchase_receivables)
    for pr in prs
      #there should now be at least one purchase in the purchases collection
      assert pr.purchases.count > 0
      #amount_paid should never be negative
      assert pr.amount_purchased >= 0
      #amount_paid should never be greater than amount
      assert pr.amount_purchased <= pr.amount
      
      for ti in pr.tote_items
        #toteitems state should not be PURCHASEPENDING anymore
        assert_not ti.status == ToteItem.states[:PURCHASEPENDING]
        #toteitems state should be either PURCHASE or PURCHASEFAILED
        if pr.kind == PurchaseReceivable.kind[:NORMAL]
          assert_equal ti.status, ToteItem.states[:PURCHASED]          
        end
        if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
          assert_equal ti.status, ToteItem.states[:PURCHASEFAILED]                    
        end
      end      
    end  

    assert_not_nil prs
    assert prs.count > 0
    puts "number of purchase receivables: #{prs.count}"

    for purchase_receivable in prs

      if purchase_receivable.kind == PurchaseReceivable.kind[:NORMAL]
        assert_equal purchase_receivable.amount, purchase_receivable.amount_purchased

        for tote_item in purchase_receivable.tote_items
          assert_equal tote_item.status, ToteItem.states[:PURCHASED]
        end        
      end

      if purchase_receivable.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        #this actually might break in the future as we add other features but it should work for our purposes now.
        #just extend it to handle the new/breaking feature if this assertion ever breaks
        assert_equal 0, purchase_receivable.amount_purchased
        assert purchase_receivable.amount > 0

        for tote_item in purchase_receivable.tote_items
          assert_equal tote_item.status, ToteItem.states[:PURCHASEFAILED]
        end        
      end            
    end

    total_purchased = 0
    total_failed_purchases = 0
    total_amount = 0
    total_amount_paid = 0
    all_purchases_succeeded = all_purchase_receivables_succeeded(prs)

    for pr in prs

      for purchase in pr.purchases
        if purchase.response.success?
          total_purchased = (total_purchased + purchase.gross_amount).round(2)
        else
          total_failed_purchases += purchase.gross_amount          
        end
      end
      total_amount = (total_amount + pr.amount).round(2)
      total_amount_paid = (total_amount_paid + pr.amount_purchased).round(2)
    end

    total_failed_purchases2 = (total_amount - total_amount_paid).round(2)
    assert_equal total_failed_purchases, total_failed_purchases2

    if all_purchases_succeeded
      assert_equal total_amount_paid, total_amount
    else
      assert total_amount_paid < total_amount
    end
    
    assert_equal total_purchased, total_amount_paid

    verify_legitimacy_of_purchases
  end

  def verify_legitimacy_of_purchases

    assert Purchase.count > 0
    assert Purchase.count == PurchaseReceivable.count

    purchase_receivables = assigns(:purchase_receivables)

    for pr in purchase_receivables
      purchase = pr.purchases.last
      assert_not_nil purchase
      authorization = Authorization.find_by(transaction_id: purchase.transaction_id)
      assert_not_nil authorization
      assert_equal authorization.transaction_id, purchase.transaction_id

      if pr.kind == PurchaseReceivable.kind[:NORMAL]
        assert_equal authorization.amount, authorization.amount_purchased                
      end

      if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        assert authorization.amount > authorization.amount_purchased        
      end

      assert_equal authorization.amount, purchase.gross_amount

    end

  end

  def number_of_failed_prs(prs)
    num = 0

    if prs.nil? || !prs.any?
      return num
    end

    for pr in prs
      if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]      
        num += 1
      end
    end  

    return num  

  end

  def all_purchase_receivables_succeeded(prs)
    return number_of_failed_prs(prs) == 0
  end

  def setup_bulk_purchase(customers)
    
    fill_all_tote_items = true
    create_bulk_buy(customers, fill_all_tote_items)
    get new_bulk_purchase_path
    assert :success
    assert_template 'bulk_purchases/new'
    #puts @response.body
    bulk_purchase = assigns(:bulk_purchase)
    assert_not_nil bulk_purchase

    #assert there are some purchase receivables
    assert_not_nil bulk_purchase.purchase_receivables
    assert bulk_purchase.purchase_receivables.to_a.count > 0
    puts "bulk_purchase.purchase_receivables.to_a.count: #{bulk_purchase.purchase_receivables.to_a.count}"

    #verify that all the pr's are legit
    for purchase_receivable in bulk_purchase.purchase_receivables
      #the amount should always be positive
      assert purchase_receivable.amount > 0
      #this should be zero here because we haven't done the producer payments yet
      assert_equal purchase_receivable.amount_purchased, 0
      assert_not_nil purchase_receivable.bulk_buys
      assert purchase_receivable.bulk_buys.count > 0

      puts "purchase_receivable.bulk_buys.count: #{purchase_receivable.bulk_buys.count}"
      
      assert_not_nil purchase_receivable.users
      assert purchase_receivable.users.count > 0

      puts "purchase_receivable.users.count: #{purchase_receivable.users.count}"

      assert_not_nil purchase_receivable.tote_items
      assert purchase_receivable.tote_items.count > 0

      puts "purchase_receivable.tote_items.count: #{purchase_receivable.tote_items.count}"

      #the filled tote items should all be marked as PURCHASEPENDING by now
      for tote_item in purchase_receivable.tote_items
        assert_equal tote_item.status, ToteItem.states[:PURCHASEPENDING]
      end

    end
    
    purchase_receivables = []

    #build up an array of purchase_receivable ids to simulate the post to create a bulk purchase
    for pr in bulk_purchase.purchase_receivables
      purchase_receivables << pr.id
    end    

    return purchase_receivables

  end

  def expected_number_payment_payables_generated(purchase_receivable)
    val = 0

    if purchase_receivable.nil?
      return val
    end

    if purchase_receivable.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
      return val
    end

    producer_ids = {}

    for tote_item in purchase_receivable.tote_items
      if !producer_ids.has_key?(tote_item.posting.user.id)
        producer_ids[tote_item.posting.user.id] = nil
      end
    end

    return producer_ids.count

  end

  def verify_proper_number_of_payment_payables
    purchase_receivables = assigns(:purchase_receivables)

    #total_expected_number_payment_payables_generated represents the computed amount of how many PurchaseReceivables we should have...
    total_expected_number_payment_payables_generated = 0

    for pr in purchase_receivables
      total_expected_number_payment_payables_generated += expected_number_payment_payables_generated(pr)
    end

    #this is the actual number of payment_payables created by this action...    
    num_payment_payables_created = assigns(:num_payment_payables_created)

    assert_equal total_expected_number_payment_payables_generated, num_payment_payables_created

    #find out how many successful prs there are
    num_successful_prs = PurchaseReceivable.count - number_of_failed_prs(PurchaseReceivable.all)    
    #there is a one-to-many relationship between a pr and a pp
    assert PaymentPayable.count >= num_successful_prs
    assert PaymentPayable.count > 0
  end

end