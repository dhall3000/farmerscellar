require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer

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

  #bundle exec rake test test/integration/bulk_purchases_test.rb
  test "do bulk buy" do
  #def skip
    purchase_receivables = setup_bulk_purchase    
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase



    verify_proper_number_of_payment_payables





    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id

    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id

  end  

  #bundle exec rake test test/integration/bulk_purchases_test.rb
  test "do bulk buy with purchase failures" do
  #def skip1
    purchase_receivables = setup_bulk_purchase            
    FakeCaptureResponse.toggle_success = true    
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    verify_legitimacy_of_bulk_purchase
    verify_proper_number_of_payment_payables    
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
      total_amount_paid += pr.amount_paid
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

    assert_equal bulk_purchase.total_gross, bulk_purchase.total_fee + bulk_purchase.total_commission + bulk_purchase.total_net    
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
      assert pr.amount_paid >= 0
      #amount_paid should never be greater than amount
      assert pr.amount_paid <= pr.amount
      
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
        assert_equal purchase_receivable.amount, purchase_receivable.amount_paid

        for tote_item in purchase_receivable.tote_items
          assert_equal tote_item.status, ToteItem.states[:PURCHASED]
        end        
      end

      if purchase_receivable.kind == PurchaseReceivable.kind[:PURCHASEFAILED]
        #this actually might break in the future as we add other features but it should work for our purposes now.
        #just extend it to handle the new/breaking feature if this assertion ever breaks
        assert_equal 0, purchase_receivable.amount_paid
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
          total_purchased += purchase.gross_amount
        else
          total_failed_purchases += purchase.gross_amount          
        end
      end
      total_amount += pr.amount
      total_amount_paid += pr.amount_paid      
    end

    total_failed_purchases2 = total_amount - total_amount_paid
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

  def setup_bulk_purchase

    fill_all_tote_items = true
    create_bulk_buy(fill_all_tote_items)
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
      assert_equal purchase_receivable.amount_paid, 0
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

end