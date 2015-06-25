require 'test_helper'
require 'bulk_buy_helper'

class BulkPurchasesTest < BulkBuyer
  # test "the truth" do
  #   assert true
  # end

  test "do bulk buy" do
  	create_bulk_buy
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
      assert purchase_receivable.amount > 0
      assert_not_nil purchase_receivable.bulk_buys
      assert purchase_receivable.bulk_buys.count > 0

      puts "purchase_receivable.bulk_buys.count: #{purchase_receivable.bulk_buys.count}"
      
      assert_not_nil purchase_receivable.users
      assert purchase_receivable.users.count > 0

      puts "purchase_receivable.users.count: #{purchase_receivable.users.count}"

      assert_not_nil purchase_receivable.tote_items
      assert purchase_receivable.tote_items.count > 0

      puts "purchase_receivable.tote_items.count: #{purchase_receivable.tote_items.count}"

      #the filled tote items should all be marked as PURCHASED by now even though technically they
      #haven't been paid for yet by the customer
      for tote_item in purchase_receivable.tote_items
        assert_equal tote_item.status, ToteItem.states[:PURCHASED]
      end
    end
    
    purchase_receivables = []

    #build up an array of purchase_receivable ids to simulate the post to create a bulk purchase
    for pr in bulk_purchase.purchase_receivables
      purchase_receivables << pr.id
    end

    assert_equal 0, PaymentPayable.count
    post bulk_purchases_path, purchase_receivables: purchase_receivables
    assert :success
    assert_template 'bulk_purchases/create'
    purchase_receivables = assigns(:purchase_receivables)
    assert_not_nil purchase_receivables
    assert purchase_receivables.count > 0
    puts "number of purchase receivables: #{purchase_receivables.count}"

    for purchase_receivable in purchase_receivables
      assert_equal purchase_receivable.amount, purchase_receivable.amount_paid
    end
    
    bulk_purchase = assigns(:bulk_purchase)
    assert_not_nil bulk_purchase
    puts "number of prs in this bp: #{bulk_purchase.purchase_receivables.to_a.count.to_s}"
    puts "number of bulk_purchases in the database: #{BulkPurchase.count.to_s}"

    assert Purchase.count > 0
    assert Purchase.count == PurchaseReceivable.count

    purchases = Purchase.all
    for purchase in purchases
      authorization = Authorization.find_by(transaction_id: purchase.transaction_id)
      assert_not_nil authorization
      assert_equal authorization.transaction_id, purchase.transaction_id
      assert_equal authorization.amount, authorization.amount_purchased
      assert_equal authorization.amount, purchase.gross_amount
      puts "-------purchase-------"
      puts "authorization.transaction_id: #{authorization.transaction_id}"
      puts "purchase.payer_id: #{purchase.payer_id}"
      puts "purchase.transaction_id: #{purchase.transaction_id}"
      puts "purchase.purchase_receivables.last.tote_items.count: #{purchase.purchase_receivables.last.tote_items.count}"
      puts "purchase.response: #{purchase.response}"
      puts "purchase.gross_amount: #{purchase.gross_amount}"
      puts "purchase.fee_amount: #{purchase.fee_amount}"
      puts "purchase.net_amount: #{purchase.net_amount}"      
    end

    puts "BulkPurchase -> total_gross: #{bulk_purchase.total_gross}, total_fee: #{bulk_purchase.total_fee}, total_commission: #{bulk_purchase.total_commission}, total_net: #{bulk_purchase.total_net}"
    puts "BulkBuy amount: #{purchase_receivables.last.bulk_buys.last.amount}"
    assert_equal purchase_receivables.last.bulk_buys.last.amount, bulk_purchase.total_gross
    assert_equal bulk_purchase.total_gross, bulk_purchase.total_fee + bulk_purchase.total_commission + bulk_purchase.total_net
    assert bulk_purchase.total_gross > 0
    assert bulk_purchase.total_fee > 0
    assert bulk_purchase.total_commission > 0
    assert bulk_purchase.total_net > 0
    assert bulk_purchase.total_gross > bulk_purchase.total_net
    assert bulk_purchase.total_net > bulk_purchase.total_commission
    assert bulk_purchase.total_commission > bulk_purchase.total_fee

    assert PaymentPayable.count > 0

    puts "PaymentPayable.count = #{PaymentPayable.count}"
    puts "unpaid PaymentPayable.count = #{PaymentPayable.where(:amount_paid < :amount).count}"

    get new_bulk_payment_path
    assert :success
    unpaid_payment_payables = assigns(:unpaid_payment_payables)
    assert_not_nil unpaid_payment_payables
    grand_total_payout = assigns(:grand_total_payout)
    puts grand_total_payout

    payment_info_by_producer_id = assigns(:payment_info_by_producer_id)    
    assert_not_nil payment_info_by_producer_id
    puts "payment_info_by_producer_id: #{payment_info_by_producer_id}"    

    puts "number of bulk payments in the database: #{BulkPayment.count}"
    puts "number of payments in the database: #{Payment.count}"
    post bulk_payments_path, payment_info_by_producer_id: payment_info_by_producer_id
    puts "number of bulk payments in the database: #{BulkPayment.count}"
    puts "BulkPayment.first.num_payees: #{BulkPayment.first.num_payees}"
    puts "BulkPayment.first.total_payments_amount: #{BulkPayment.first.total_payments_amount}"

    puts "number of payments in the database: #{Payment.count}"

    Payment.all.each do |payment|
      puts "payment id: #{payment.id}, payment amount: #{payment.amount}"
    end

    puts assigns(:num_payees)
    puts assigns(:cumulative_total_payout)   






    #puts "-------------------PaymentPayable---------------"

    #for payment_payable in PaymentPayable.all
    #  puts "id: #{payment_payable.id}, amount: #{payment_payable.amount}, amount_paid: #{payment_payable.amount_paid}, producer: #{payment_payable.users.last.name}"

    #  for tote_item in payment_payable.tote_items
    #    puts "     #{tote_item.posting.product.name}, amount: #{tote_item.quantity * tote_item.price}"
    #  end

    #end

  end
end
