require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer

  test "do upside down bulk buy" do

    #this test is for beta / launch mode when we're charging flat processor fees and 0% commission service fee
    #in this scenario we can/will end up with transactions we're upside down on...paying more to the producer
    #than we're collecting from Paypal. fun.
    customers = [@c_one_tote_item]
    purchase_receivables = setup_bulk_purchase(customers)
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase({sales_underwater: 1, commission_zero: 1})
    bulk_purchase = assigns(:bulk_purchase)
    do_standard_payment(customers)
    bulk_payment = assigns(:bulk_payment)

  end

  test "do ricky tests" do

    customers = [@c1]
    purchase_receivables = setup_bulk_purchase(customers)
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase
    bulk_purchase = assigns(:bulk_purchase)
    do_standard_payment(customers)
    bulk_payment = assigns(:bulk_payment)

    ti = bulk_purchase.purchase_receivables[2].tote_items.first
    c1_charge_amount = (ti.quantity * ti.price).round(2)
    ricky_proceeds = (c1_charge_amount * (0.965)).round(2)
    assert_equal ricky_proceeds, bulk_payment.payment_payables[10].payments.first.amount

  end

  def do_standard_payment(customers)
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

    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount    

    #these tests are to verify that the html table in the producer payment invoice has values
    #that all make sense. that is, the unit_count times unit_price should equal the sub_total and
    #the sum of the sub_totals should equal the total
    #@payment_invoice_infos << {total: total_amount, posting_infos: posting_infos}
    #posting_info looks like this: {unit_count: 0, unit_price: 0, sub_total: 0}
    payment_invoice_infos = assigns(:payment_invoice_infos)
    payment_invoice_infos.each do |payment_invoice_info|
      verify_payment_invoice_info(payment_invoice_info)
    end   
    
  end

  #a posting info is a hash like this: #{unit_count: 0, unit_price: 0, sub_total: 0}
  #it comes from bulkpaymentscontroller#get_posting_infos
  def verify_payment_invoice_info(payment_invoice_info)

    total = payment_invoice_info[:total]
    posting_infos = payment_invoice_info[:posting_infos]

    sub_totals = 0

    posting_infos.each do |posting, value|
      
      sub_total = value[:sub_total]
      units_sum = 0
      i = 0
      while i < value[:unit_count]
        units_sum = (units_sum + value[:unit_price]).round(2)
        i = i + 1
      end

      assert_equal sub_total, units_sum
      sub_totals = (sub_totals + sub_total).round(2)

    end

    assert_equal total.to_f, sub_totals

  end

  #bundle exec rake test test/integration/bulk_purchases_test.rb test_do_bulk_buy
  test "do bulk buy" do
    do_bulk_buy
    do_delivery
  end

  test "do pickups" do    
    do_bulk_buy
    do_delivery

    #find the earliest and latest delivery dates among c1's toteitems
    tote_items = @c1.tote_items
    earliest_delivery_date = 100.days.from_now
    latest_delivery_date = 100.days.ago
    tote_items.each do |ti|
      if ti.posting.delivery_date < earliest_delivery_date
        earliest_delivery_date = ti.posting.delivery_date
      end
      if ti.posting.delivery_date > latest_delivery_date
        latest_delivery_date = ti.posting.delivery_date
      end
    end

    #split the difference, time wise
    middle_date = earliest_delivery_date + ((latest_delivery_date - earliest_delivery_date) / 2)    
    #jump to that middle-ground time
    travel_to middle_date
    #do a pickup
    log_in_as(users(:dropsite1))
    post pickups_path, pickup_code: @c1.pickup_code.code
    tote_items = assigns(:tote_items)
    #verify the number of items is less than the total amount    
    assert tote_items.count < @c1.tote_items.count
    #save the number picked up for later comparison
    num_items_first_pickup_count = tote_items.count
    assert num_items_first_pickup_count > 0
    #jump to one day after the last delivery day
    travel_to latest_delivery_date + 1.day
    #hit c1's model object for the number of items remaining to pick up
    num_items_second_pickup_count = @c1.tote_items_to_pickup.count
    assert num_items_second_pickup_count > 0
    #compare this remaining-to-pick-up number to the number already picked up to the total number of items
    assert_equal @c1.tote_items.count, num_items_first_pickup_count + num_items_second_pickup_count
    #jump forward 7 days from now
    travel_to Time.zone.now + 7.days
    #hit c1's model object for the number of items remaining to pick up
    #verify it's zero since they should all be beyond the 7 day max holding period
    assert_equal 0, @c1.tote_items_to_pickup.count    
    #jump back to one day after the last delivery date
    travel_to latest_delivery_date + 1.day    
    #post a pickup
    post pickups_path, pickup_code: @c1.pickup_code.code
    tote_items = assigns(:tote_items)
    #verify proper number of items picked up
    assert_equal num_items_second_pickup_count, tote_items.count
    #post another pickup
    post pickups_path, pickup_code: @c1.pickup_code.code
    tote_items = assigns(:tote_items)
    #verify no more items picked up
    assert_equal 0, tote_items.count

    travel_back

  end

  def do_bulk_buy
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

    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount    
  end

  def do_delivery
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
    assert_equal ToteItem.where(state: ToteItem.states[:ADDED], user_id: customer.id).count, 0
    assert_equal ToteItem.where(state: ToteItem.states[:AUTHORIZED], user_id: customer.id).count, 0
    assert_equal ToteItem.where(state: ToteItem.states[:COMMITTED], user_id: customer.id).count, 0

    posting_lettuce = postings(:postingf1lettuce)
    log_in_as(customer)   

    #try to pull up the buy form for a particular posting
    get new_tote_item_path(posting_id: posting_lettuce.id)

    #check for the existence of nasty-gram related to account state
    if account_ok
      assert_select 'p', count: 0, text: "Your account is on hold, most likely due to a positive balance on your account. Please contact Farmer's Cellar to pay your balance before continuing to shop."
      #there should be 6 paragraphs now on the form cause a whole bunch of mini fixed-amount buttons were added to the Add to Tote form
      assert_select 'p', 2
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
    assert_equal ToteItem.where(state: ToteItem.states[:REMOVED]).count, 0

    #authorize some more tote items
    log_in_as(@c1)
    posting_lettuce = postings(:postingf1lettuce)
    post tote_items_path, tote_item: {quantity: 2, price: posting_lettuce.price, state: ToteItem.states[:ADDED], posting_id: posting_lettuce.id, user_id: @c1.id}
    get tote_items_path
    total_amount_to_authorize = assigns(:total_amount_to_authorize)    
    post checkouts_path, amount: total_amount_to_authorize, use_reference_transaction: "0"
    follow_redirect!
    authorization = assigns(:authorization)
    post authorizations_path, authorization: {token: authorization.token, payer_id: authorization.payer_id, amount: authorization.amount}
    authorization = assigns(:authorization)    

    #add some more toteitems    
    posting_tomato = postings(:postingf2tomato)
    post tote_items_path, tote_item: {quantity: 2, price: posting_tomato.price, state: ToteItem.states[:ADDED], posting_id: posting_tomato.id, user_id: @c1.id}

    #by the time we get to this point c1 should have 10 toteitems, 8 in PURCHASEPENDING, 1 in ADDED and 1 in AUTHORIZED

    ActionMailer::Base.deliveries.clear
    previous_user_account_state_count = UserAccountState.count

    log_in_as(@a1)
    FakeCaptureResponse.toggle_success = true    
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    
    #COMMENT KEY 000
    assert_equal ToteItem.where(state: ToteItem.states[:REMOVED]).count, 2
    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables    
    bulk_purchase = assigns(:bulk_purchase)

    failed_pr_count = 0
    bulk_purchase.purchase_receivables.each do |pr|
      if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        failed_pr_count += 1
      end
    end

    assert failed_pr_count > 0
    assert UserAccountState.count, previous_user_account_state_count
    assert 1, UserAccountState.order(:created_at).last.account_state.state
    
    bulk_purchase.do_bulk_email_communication
    verify_proper_purchase_receipt_emails(bulk_purchase)

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

    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount    

    FakeCaptureResponse.toggle_success = false    
    FakeCaptureResponse.succeed = true

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
    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount

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
    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount

  end

  def verify_legitimacy_of_bulk_purchase(options = {})
    assert :success
    assert_template 'bulk_purchases/create'
    purchase_receivables = assigns(:purchase_receivables)    
    bp = assigns(:bulk_purchase)
    assert_not_nil bp

    prs = bp.purchase_receivables

    total_amount_purchased = 0
    for pr in prs
      #NOTE!! it looks like i've done a good job to date of avoiding putting .round(2) in the test code anywhere. but
      #i came across a failure where it really seems like it's the summing of the total_amount_purchased var that is
      #causing the funky values. I was able to duplicte this in a terminal like this:
      #irb(main):007:0> amount = 150.91 + 91.0+100.5+82.0
      #=> 424.40999999999997
      total_amount_purchased = (total_amount_purchased + pr.amount_purchased).round(2)
    end

    #total up the amount purchased in another way and verify the two ways are equivalent
    total_amount_purchased2 = 0

    purchase_receivables.each do |pr|
      total_amount_purchased2 = total_amount_purchased2 + pr.amount_purchased
    end

    assert_equal total_amount_purchased, total_amount_purchased2
    
    #verify sum of pr amountpurchaseds == bulkpurchase.totalgross
    assert_equal total_amount_purchased, bp.gross
    all_purchases_succeeded = all_purchase_receivables_succeeded(prs)

    #verify the total amount withheld from us equals the sum of the parts
    sum_of_payment_processor_fee_withheld_from_us = 0
    sum_of_payment_processor_fee_withheld_from_producer = 0

    purchases = {}

    purchase_receivables.each do |pr|
      purchase = pr.purchases.last

      if !purchases.has_key?(purchase)
        purchases[purchase] = purchase
        sum_of_payment_processor_fee_withheld_from_us = (sum_of_payment_processor_fee_withheld_from_us + purchase.payment_processor_fee_withheld_from_us).round(2)
        sum_of_payment_processor_fee_withheld_from_producer = (sum_of_payment_processor_fee_withheld_from_producer + purchase.payment_processor_fee_withheld_from_producer).round(2)
      end
      
    end

    assert_equal sum_of_payment_processor_fee_withheld_from_us, bp.payment_processor_fee_withheld_from_us    
    assert_equal sum_of_payment_processor_fee_withheld_from_producer, bp.payment_processor_fee_withheld_from_producer

    #NOTE!! it looks like i've done a good job to date of avoiding putting .round(2) in the test code anywhere. but
    #i came across a failure where it really seems like it's the summing of the total_amount_purchased var that is
    #causing the funky values. I was able to duplicte this in a terminal like this:
    #irb(main):008:0> amount = 14.87+32.66+376.89
    #=> 424.41999999999996

    sales = (bp.commission + bp.payment_processor_fee_withheld_from_producer - bp.payment_processor_fee_withheld_from_us).round(2)
    assert_equal bp.gross, (bp.payment_processor_fee_withheld_from_us + bp.net + sales).round(2)

    if options[:sales_underwater] == 1
      assert sales < 0, "sales not < 0: " + sales.to_s
    else
      assert sales > 0
    end

    puts "bulk_purchase.gross: " + bp.gross.to_s
    puts "bulk_purchase.payment_processor_fee_withheld_from_us: " + bp.payment_processor_fee_withheld_from_us.to_s
    puts "bulk_purchase.payment_processor_fee_withheld_from_producer: " + bp.payment_processor_fee_withheld_from_producer.to_s
    puts "bulk_purchase.net: " + bp.net.to_s
    puts "bulk_purchase.commission: " + bp.commission.to_s
    puts "sales: " + sales.to_s

    assert bp.gross > 0
    assert bp.payment_processor_fee_withheld_from_us > 0

    if options[:commission_zero] == 1 
      assert_equal bp.commission, 0
    else
      assert bp.commission > 0
    end
    
    assert bp.net > 0
    assert bp.gross > bp.net
    assert bp.net > bp.commission
  
    verify_legitimacy_of_purchase_receivables

  end

  def get_email_for(email)

    messages = []

    ActionMailer::Base.deliveries.each do |mail|
      if mail.to == [email]
        messages << mail
      end
    end

    return messages

  end

  def verify_proper_purchase_receipt_emails(bulk_purchase)
    
    user_ids = []
    bulk_purchase.purchase_receivables.each do |pr|

      user = pr.users.last
      user_ids << user.id

      messages = get_email_for(user.email)

      #there should only be one email for this user
      assert_equal 1, messages.count

      mail = messages[0]
      if mail.to == ["david@farmerscellar.com"]

      else

        assert_equal [user.email], mail.to
        assert_equal ["david@farmerscellar.com"], mail.from
        assert_equal "Purchase receipt", mail.subject
        assert_match "Here is your Farmer's Cellar purchase receipt.", mail.body.encoded

        if pr.kind == PurchaseReceivable.kind[:NORMAL]
          assert_match "Your payment account was charged a total of", mail.body.encoded
        elsif pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
          assert_match "There was a problem with your purchase transaction.", mail.body.encoded
          assert_match "Please contact", mail.body.encoded
          assert_match "to ensure your account balance is paid in full.", mail.body.encoded
        elsif pr.kind == PurchaseReceivable.kind[:DONTCOLLECT]
        else
        end            

      end

    end

    uniq_user_ids = user_ids.uniq

    #there should be one email (purchase receipt) mailed for each customer represented in the
    #bulk_purchase.purchase_receivables association
    assert_equal uniq_user_ids.count + 1, ActionMailer::Base.deliveries.count
    
  end

  def verify_legitimacy_of_purchase_receivables
    prs = assigns(:purchase_receivables)
    for pr in prs
      #there should now be at least one purchase in the purchases collection
      assert pr.purchases.count > 0
      #amount_purchased should never be negative
      assert pr.amount_purchased >= 0
      #amount_purchased should never be greater than amount
      assert pr.amount_purchased <= pr.amount
      
      for ti in pr.tote_items
        #toteitems state should not be PURCHASEPENDING anymore
        assert_not ti.state == ToteItem.states[:PURCHASEPENDING]
        #toteitems state should be either PURCHASE or PURCHASEFAILED
        if pr.kind == PurchaseReceivable.kind[:NORMAL]
          assert_equal ti.state, ToteItem.states[:PURCHASED]          
        end
        if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
          assert_equal ti.state, ToteItem.states[:PURCHASEFAILED]                    
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
          assert_equal tote_item.state, ToteItem.states[:PURCHASED]
        end        
      end

      if purchase_receivable.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        #this actually might break in the future as we add other features but it should work for our purposes now.
        #just extend it to handle the new/breaking feature if this assertion ever breaks
        assert_equal 0, purchase_receivable.amount_purchased
        assert purchase_receivable.amount > 0

        for tote_item in purchase_receivable.tote_items
          assert_equal tote_item.state, ToteItem.states[:PURCHASEFAILED]
        end        
      end            
    end

    total_purchased = 0
    total_failed_purchases = 0
    total_amount = 0
    total_amount_purchased = 0
    all_purchases_succeeded = all_purchase_receivables_succeeded(prs)

    for pr in prs

      assert pr.purchases.count > 0

      if pr.purchases.first.response.success?
        total_purchased = (total_purchased + pr.amount_purchased).round(2)
      else
        total_failed_purchases = (total_failed_purchases + (pr.amount - pr.amount_purchased)).round(2)
      end

      for purchase in pr.purchases
        if purchase.response.success?
#          total_purchased = (total_purchased + purchase.gross_amount).round(2)
        else
#          total_failed_purchases += purchase.gross_amount          
        end
      end
      total_amount = (total_amount + pr.amount).round(2)
      total_amount_purchased = (total_amount_purchased + pr.amount_purchased).round(2)
    end

    total_failed_purchases2 = (total_amount - total_amount_purchased).round(2)
    assert_equal total_failed_purchases, total_failed_purchases2

    if all_purchases_succeeded
      assert_equal total_amount_purchased, total_amount
    else
      assert total_amount_purchased < total_amount
    end
    
    assert_equal total_purchased, total_amount_purchased

    verify_legitimacy_of_purchases
  end

  def verify_legitimacy_of_purchases

    assert Purchase.count > 0

    assert_equal Purchase.count, ToteItem.select(:user_id).where(state: [ToteItem.states[:PURCHASEFAILED], ToteItem.states[:PURCHASED]]).distinct.count
    assert_equal PurchaseReceivable.count, ToteItem.where(state: [ToteItem.states[:PURCHASEFAILED], ToteItem.states[:PURCHASED]]).distinct.count

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

      if purchase.response.success?
        assert_equal authorization.amount, purchase.gross_amount        
      else
        assert_equal authorization.amount, pr.purchases.last.purchase_receivables.sum(:amount)
        assert_equal 0, pr.purchases.last.purchase_receivables.sum(:amount_purchased)
      end

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

      puts "purchase_receivable.bulk_buys.count: #{purchase_receivable.bulk_buys.count}"
      
      assert_not_nil purchase_receivable.users
      assert purchase_receivable.users.count > 0

      puts "purchase_receivable.users.count: #{purchase_receivable.users.count}"

      assert_not_nil purchase_receivable.tote_items
      assert purchase_receivable.tote_items.count > 0

      puts "purchase_receivable.tote_items.count: #{purchase_receivable.tote_items.count}"

      #the filled tote items should all be marked as PURCHASEPENDING by now
      for tote_item in purchase_receivable.tote_items
        assert_equal tote_item.state, ToteItem.states[:PURCHASEPENDING]
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