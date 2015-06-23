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

  end
end
