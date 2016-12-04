require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer

  test "do upside down bulk buy" do

    #this test is for beta / launch mode when we're charging flat processor fees and 0% commission service fee
    #in this scenario we can/will end up with transactions we're upside down on...paying more to the producer
    #than we're collecting from Paypal. fun.

    assert_equal 0, PaymentPayable.where("amount <> amount_paid").count

    customers = [@c_one_tote_item]
    purchase_receivables = setup_bulk_purchase(customers)

    posting = @c_one_tote_item.tote_items.first.posting

    travel_to posting.commitment_zone_start
    RakeHelper.do_hourly_tasks
    travel_to posting.delivery_date + 12.hours
    fill_posting(posting)
    travel_to posting.delivery_date + 22.hours
    RakeHelper.do_hourly_tasks

    verify_legitimacy_of_bulk_purchase({sales_underwater: 1, commission_zero: 1})
    do_standard_payment(customers)

    travel_back

  end

  test "do ricky tests" do

    customers = [@c1]    
    purchase_receivables = setup_bulk_purchase(customers)
    assert_equal 0, BulkPurchase.count

    posting = @c1.tote_items.first.posting    
    travel_to posting.commitment_zone_start
    RakeHelper.do_hourly_tasks
    travel_to posting.delivery_date + 22.hours
    RakeHelper.do_hourly_tasks
    assert_equal 1, BulkPurchase.count

    verify_legitimacy_of_bulk_purchase
    do_standard_payment(customers)

    bulk_purchase = BulkPurchase.last
    bulk_payment = BulkPayment.last
    
    pj_ti_index = 8
    ti = @c1.tote_items[pj_ti_index]
    c1_charge_amount = (ti.quantity * ti.price).round(2)
    ricky_proceeds = (c1_charge_amount * (0.965)).round(2)
    assert_equal ricky_proceeds, bulk_payment.payment_payables[pj_ti_index].payments.first.amount

    travel_back

  end

  def do_standard_payment(customers)
    verify_proper_number_of_payment_payables    
    bulk_purchase = BulkPurchase.last
    verify_proper_account_states(customers)
    log_in_as(@a1)

    unpaid_payment_payables = PaymentPayable.where("amount <> amount_paid")

    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    bulk_payment = BulkPayment.last

    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount        
  end

  #bundle exec rake test test/integration/bulk_purchases_test.rb test_do_bulk_buy
  test "do bulk buy" do
    do_bulk_buy
    do_delivery
    travel_back
  end

  test "do pickups" do    
    do_bulk_buy
    do_delivery

    earliest_delivery_date = @c1.tote_items.joins(:posting).order("postings.delivery_date").first.posting.delivery_date
    latest_delivery_date = @c1.tote_items.joins(:posting).order("postings.delivery_date").last.posting.delivery_date
    #jump to just after to the earliest delivery date
    travel_to earliest_delivery_date + 1.second
    #do a pickup
    log_in_as(users(:dropsite1))
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    #verify there are no messages informing user of sub-fully-filled items
    assert_no_match "We couldn't fully fill this order.", response.body
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
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    tote_items = assigns(:tote_items)
    #verify proper number of items picked up
    assert_equal num_items_second_pickup_count, tote_items.count
    #post another pickup after 61 minutes
    travel_to Time.zone.now + 61.minutes
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    tote_items = assigns(:tote_items)
    #verify no more items picked up
    assert_equal 0, tote_items.count

    travel_back

  end

  test "pickups should notify user of partially and zero filled items" do    
    do_bulk_buy
    do_delivery

    earliest_delivery_date = @c1.tote_items.joins(:posting).order("postings.delivery_date").first.posting.delivery_date
    latest_delivery_date = @c1.tote_items.joins(:posting).order("postings.delivery_date").last.posting.delivery_date
    #jump to just after to the earliest delivery date
    travel_to earliest_delivery_date + 1.second
    #do a pickup
    log_in_as(users(:dropsite1))    
    #scab in some tote items that aren't fully filled
    posting = @c1.tote_items_to_pickup.first.posting
    assert ToteItem.create(quantity: 5, quantity_filled: 3, price: posting.price, posting: posting, user: @c1, state: ToteItem.states[:FILLED])
    assert ToteItem.create(quantity: 5, price: posting.price, posting: posting, user: @c1, state: ToteItem.states[:NOTFILLED])
    #user enters their pickup code at kiosk
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    assert_response :success
    #verify user is looking at the pickups page with a list of product to pick up
    assert_template 'pickups/create'    
    #verify that the un-fully filled items exist in the tote_items object
    tote_items = assigns(:tote_items)
    partially_filled_found = false
    not_filled_found = false
    tote_items.each do |ti|
      if ti.quantity_filled == 0
        not_filled_found = true
      end
      if ti.quantity_filled < ti.quantity
        partially_filled_found = true
      end
    end
    assert partially_filled_found
    assert not_filled_found
    #verify a message is displayed notifying user of partially filled item
    assert_select 'div', count: 1, text: "3 Wholes. We couldn't fully fill this order."
    #verify a message is displayed notifying user of not filled item
    assert_select 'div', count: 1, text: "0 Wholes. We couldn't fully fill this order."


    #the rest of this test is superfluous to the intent of this test. it's just an artifact of copy/pasting test "do pickups" do
    #as a starting point for this test. leaving it in, whatever...

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
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    tote_items = assigns(:tote_items)
    #verify proper number of items picked up
    assert_equal num_items_second_pickup_count, tote_items.count
    #post another pickup after 61 minutes
    travel_to Time.zone.now + 61.minutes
    post pickups_path, params: {pickup_code: @c1.pickup_code.code}
    tote_items = assigns(:tote_items)
    #verify no more items picked up
    assert_equal 0, tote_items.count

    travel_back

  end

  def do_bulk_buy

    assert_equal 0, BulkPurchase.count
    assert_equal 0, BulkPayment.count

    customers = [@c1, @c2, @c3, @c4]
    purchase_receivables = setup_bulk_purchase(customers)

    now = Time.zone.now
    travel_to now.midnight + 22.hours
    RakeHelper.do_hourly_tasks
    travel_to now

    assert_equal 1, BulkPurchase.count
    assert_equal 1, BulkPayment.count

    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables
    
    bulk_purchase = BulkPurchase.last

    assert :success
    unpaid_payment_payables = PaymentPayable.where("amount_paid < amount")

    assert_not_nil unpaid_payment_payables
    bulk_payment = BulkPayment.last

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

    post deliveries_path, params: {posting_ids: ids}
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
      patch delivery_path(delivery), params: {dropsite_id: dropsite.id}
    end

  end

  def verify_proper_account_states(customers)
    
    customers.each do |customer|
      verify_proper_account_state(customer)
    end

  end

  def verify_proper_account_state(customer)
    
    account_ok = customer.user_account_states.order(:created_at).last.account_state.state == AccountState.states[:OK]
    log_in_as(customer)   

    #try to pull up the buy form for a particular posting
    get new_tote_item_path(posting_id: Posting.last.id)

    #check for the existence of nasty-gram related to account state
    if account_ok
      assert_select 'p', count: 0, text: "Your account is on hold, most likely due to a positive balance on your account. Please contact Farmer's Cellar to pay your balance before continuing to shop."      
      #this is a spot check of what should be healthy functioning row of quantity-add buttons that say "+1", "+2", "+3" and "+4". check to make sure the "+2" button exists and that no buttons are disabled
      assert_select "table.table tbody tr td form.tote_addition_one_button_form input[value=?]", "+2"      
      assert_select "table.table tbody tr td form.tote_addition_one_button_form input[disabled=?]", "disabled", 0
    else
      assert_select 'p', "Your account is on hold, most likely due to a positive balance on your account. Please contact Farmer's Cellar to pay your balance before continuing to shop."
      #verify the existence of disabled buttons. these are the buttons user pokes to add quantity
      assert_select "table.table tbody tr td form.tote_addition_one_button_form input[disabled=?]", "disabled"
    end    

    #TODO: verify can't add new tote items
    
  end

  #bundle exec rake test test/integration/bulk_purchases_test.rb
  test "do bulk buy with purchase failures" do

    nuke_all_tote_items
    nuke_all_postings
    nuke_all_users

    admin = create_admin
    producer1 = create_producer(name = "producer1", email = "producer1@p.com")
    producer2 = create_producer(name = "producer2", email = "producer2@p.com")

    x1 = create_new_customer("x1", "x1@c.com")
    x2 = create_new_customer("x2", "x2@c.com")
    x3 = create_new_customer("x3", "x3@c.com")
    x4 = create_new_customer("x4", "x4@c.com")

    posting11 = create_posting(producer1, price = 2, get_product("Apples"), get_unit("Pound"), get_delivery_date(7), get_delivery_date(5))
    posting12 = create_posting(producer1, price = 4, get_product("Mango"), get_unit("Pound"), get_delivery_date(7), get_delivery_date(5))
    posting21 = create_posting(producer2, price = 8, get_product("Giraffe Milk"), get_unit("Pound"), get_delivery_date(14), get_delivery_date(12))
    posting22 = create_posting(producer2, price = 16, get_product("Raisin"), get_unit("Pound"), get_delivery_date(14), get_delivery_date(12))

    create_tote_item(x1, posting11, quantity = 2)
    create_tote_item(x1, posting12, quantity = 2)
    create_tote_item(x1, posting21, quantity = 2)

    create_tote_item(x2, posting11, quantity = 2)
    create_tote_item(x2, posting12, quantity = 2)

    create_tote_item(x3, posting21, quantity = 2)
    create_tote_item(x3, posting22, quantity = 2)

    create_tote_item(x4, posting21, quantity = 2)
    create_tote_item(x4, posting22, quantity = 2)

    create_one_time_authorization_for_customer(x1)
    create_one_time_authorization_for_customer(x2)
    create_one_time_authorization_for_customer(x3)
    create_one_time_authorization_for_customer(x4)

    #by the time we get to this point c1 should have 10 toteitems, 8 in PURCHASEPENDING, 1 in ADDED and 1 in AUTHORIZED

    ActionMailer::Base.deliveries.clear
    previous_user_account_state_count = UserAccountState.count

    travel_to posting11.commitment_zone_start
    RakeHelper.do_hourly_tasks

    fully_fill_creditor_order(posting11.reload.creditor_order)

    log_in_as(get_admin)
    FakeCaptureResponse.toggle_success = true    
    travel_to posting11.delivery_date + 22.hours
    RakeHelper.do_hourly_tasks
    
    #COMMENT KEY 000
    assert_equal 1, ToteItem.where(user: x1, state: ToteItem.states[:REMOVED]).count
    verify_legitimacy_of_bulk_purchase

    verify_proper_number_of_payment_payables    
    bulk_purchase = BulkPurchase.last

    failed_pr_count = 0
    bulk_purchase.purchase_receivables.each do |pr|
      if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        failed_pr_count += 1
      end
    end

    assert failed_pr_count > 0
    assert UserAccountState.count, previous_user_account_state_count
    assert 1, UserAccountState.order(:created_at).last.account_state.state
    
    verify_proper_purchase_receipt_emails(bulk_purchase)    
    verify_proper_account_states([x1, x2, x3, x4])
    log_in_as(get_admin)
    
    bulk_payment = BulkPayment.last

    assert bulk_purchase.net > 0
    assert bulk_payment.total_payments_amount, bulk_purchase.net

    FakeCaptureResponse.toggle_success = false    
    FakeCaptureResponse.succeed = true

    travel_back

  end

  test "sequential bulk buys with some purchase failures" do

    nuke_all_tote_items
    nuke_all_postings
    nuke_all_users

    admin = create_admin
    producer1 = create_producer(name = "producer1", email = "producer1@p.com")
    producer2 = create_producer(name = "producer2", email = "producer2@p.com")

    x1 = create_new_customer("x1", "x1@c.com")
    x2 = create_new_customer("x2", "x2@c.com")
    x3 = create_new_customer("x3", "x3@c.com")
    x4 = create_new_customer("x4", "x4@c.com")

    posting11 = create_posting(producer1, price = 2, get_product("Apples"), get_unit("Pound"), get_delivery_date(7), get_delivery_date(5))
    posting12 = create_posting(producer1, price = 4, get_product("Mango"), get_unit("Pound"), get_delivery_date(7), get_delivery_date(5))
    posting21 = create_posting(producer2, price = 8, get_product("Giraffe Milk"), get_unit("Pound"), get_delivery_date(14), get_delivery_date(12))
    posting22 = create_posting(producer2, price = 16, get_product("Raisin"), get_unit("Pound"), get_delivery_date(14), get_delivery_date(12))

    create_tote_item(x1, posting11, quantity = 2)
    create_tote_item(x1, posting12, quantity = 2)
    create_tote_item(x2, posting11, quantity = 2)
    create_tote_item(x2, posting12, quantity = 2)

    create_tote_item(x3, posting21, quantity = 2)
    create_tote_item(x3, posting22, quantity = 2)
    create_tote_item(x4, posting21, quantity = 2)
    create_tote_item(x4, posting22, quantity = 2)

    create_one_time_authorization_for_customer(x1)
    create_one_time_authorization_for_customer(x2)
    create_one_time_authorization_for_customer(x3)
    create_one_time_authorization_for_customer(x4)

    FakeCaptureResponse.toggle_success = true    

    assert_equal 0, BulkPurchase.count
    assert_equal 0, BulkPayment.count

    do_authorized_through_funds_transfer(posting11)

    assert_equal 1, BulkPurchase.count
    assert_equal 1, BulkPayment.count

    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables    

    bulk_purchase = BulkPurchase.last
    bulk_payment = BulkPayment.last    

    assert bulk_purchase.net > 0
    assert bulk_payment.total_payments_amount > bulk_purchase.net

    FakeCaptureResponse.toggle_success = false    
    FakeCaptureResponse.succeed = true

    do_authorized_through_funds_transfer(posting22)

    assert_equal 2, BulkPurchase.count
    assert_equal 2, BulkPayment.count

    verify_legitimacy_of_bulk_purchase    
    verify_proper_number_of_payment_payables    

    bulk_purchase = BulkPurchase.last
    bulk_payment = BulkPayment.last    
    
    assert_equal bulk_purchase.net, bulk_payment.total_payments_amount

    travel_back

  end

  def verify_legitimacy_of_bulk_purchase(options = {})
    bp = BulkPurchase.last
    purchase_receivables = bp.purchase_receivables
    assert_not_nil bp    

    total_amount_purchased = 0
    purchase_receivables.each do |pr|
      #NOTE!! it looks like i've done a good job to date of avoiding putting .round(2) in the test code anywhere. but
      #i came across a failure where it really seems like it's the summing of the total_amount_purchased var that is
      #causing the funky values. I was able to duplicte this in a terminal like this:
      #irb(main):007:0> amount = 150.91 + 91.0+100.5+82.0
      #=> 424.40999999999997
      total_amount_purchased = (total_amount_purchased + pr.amount_purchased).round(2)
    end
   
    #verify sum of pr amountpurchaseds == bulkpurchase.totalgross
    assert_equal total_amount_purchased, bp.gross
    all_purchases_succeeded = all_purchase_receivables_succeeded(purchase_receivables)

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
  
    verify_legitimacy_of_purchase_receivables(purchase_receivables)

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
        else
        end            

      end

    end

    uniq_user_ids = user_ids.uniq

    num_purchase_receipts = 0
    ActionMailer::Base.deliveries.each do |mail|

      if mail.subject == "Purchase receipt"
        num_purchase_receipts += 1
      end

    end

    #there should be one email (purchase receipt) mailed for each customer represented in the
    #bulk_purchase.purchase_receivables association
    assert_equal uniq_user_ids.count, num_purchase_receipts
    
  end

  def verify_legitimacy_of_purchase_receivables(prs = nil)

    if prs.nil?
      prs = assigns(:purchase_receivables)
    end

    for pr in prs
      #there should now be at least one purchase in the purchases collection
      assert pr.purchases.count > 0
      #amount_purchased should never be negative
      assert pr.amount_purchased >= 0
      #amount_purchased should never be greater than amount
      assert pr.amount_purchased <= pr.amount
      
      for ti in pr.tote_items
        #once upon a time it was the case that toteitems state should not be PURCHASEPENDING anymore.
        #this means that they should (once upon a time) have been IN ppending. now that we've
        #yanked ppending from the list of available states that a toteitem can be in, these ti's should
        #now all be simply in the FILLED state while its associated purchasereceivable should be
        #in the PURCHASEFAILED state if there was a problem
        if pr.kind == PurchaseReceivable.kind[:NORMAL]
          assert_equal pr.state, PurchaseReceivable.states[:COMPLETE]          
        end
        if pr.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
          assert_equal pr.state, PurchaseReceivable.states[:READY]
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
          assert_equal tote_item.state, ToteItem.states[:FILLED]
        end        
      end

      if purchase_receivable.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        #this actually might break in the future as we add other features but it should work for our purposes now.
        #just extend it to handle the new/breaking feature if this assertion ever breaks
        assert_equal 0, purchase_receivable.amount_purchased
        assert purchase_receivable.amount > 0

        for tote_item in purchase_receivable.tote_items
          assert_equal tote_item.state, ToteItem.states[:FILLED]
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

    verify_legitimacy_of_purchases(prs)
  end

  def verify_legitimacy_of_purchases(purchase_receivables = nil)

    assert Purchase.count > 0

    assert_equal Purchase.count, ToteItem.select(:user_id).where(state: [ToteItem.states[:FILLED]]).distinct.count
    assert_equal PurchaseReceivable.count, ToteItem.where(state: [ToteItem.states[:FILLED]]).distinct.count

    if purchase_receivables.nil?
      purchase_receivables = assigns(:purchase_receivables)
    end

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
        assert pr.purchases.last.purchase_receivables.sum(:amount) <= authorization.amount
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
    
    order_cutoffs = []    

    customers.each do |customer|
      
      create_one_time_authorization_for_customer(customer)

      customer.tote_items.each do |tote_item|
        order_cutoffs << tote_item.posting.commitment_zone_start
      end

    end

    assert_equal 0, CreditorOrder.count

    order_cutoffs = order_cutoffs.uniq.sort

    order_cutoffs.each do |order_cutoff|
      travel_to order_cutoff
      RakeHelper.do_hourly_tasks
    end

    assert_equal 0, PurchaseReceivable.count

    CreditorOrder.all.each do |creditor_order|
      fully_fill_creditor_order(creditor_order)
    end

    assert PurchaseReceivable.count > 0
    assert_equal 0, BulkPurchase.count

    #verify that all the pr's are legit
    PurchaseReceivable.all.each do |purchase_receivable|
      #the amount should always be positive
      assert purchase_receivable.amount > 0
      #this should be zero here because we haven't done the producer payments yet
      assert_equal 0, purchase_receivable.amount_purchased
      assert_equal PurchaseReceivable.states[:READY], purchase_receivable.state
      assert_not_nil purchase_receivable.bulk_buys

      puts "purchase_receivable.bulk_buys.count: #{purchase_receivable.bulk_buys.count}"
      
      assert_not_nil purchase_receivable.users
      assert purchase_receivable.users.count > 0

      puts "purchase_receivable.users.count: #{purchase_receivable.users.count}"

      assert_not_nil purchase_receivable.tote_items
      assert purchase_receivable.tote_items.count > 0

      puts "purchase_receivable.tote_items.count: #{purchase_receivable.tote_items.count}"

      #the filled tote items should all be marked as FILLED
      for tote_item in purchase_receivable.tote_items
        assert_equal tote_item.state, ToteItem.states[:FILLED]
      end

    end
    
    purchase_receivables = []

    #build up an array of purchase_receivable ids to simulate the post to create a bulk purchase
    for pr in PurchaseReceivable.all
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

    assert_equal PurchaseReceivable.count, PaymentPayable.count
    purchase_receivables = assigns(:purchase_receivables)

    #this is the actual number of payment_payables created by this action...    
    num_payment_payables_created = assigns(:num_payment_payables_created)

    assert PaymentPayable.count > 0
  end

end