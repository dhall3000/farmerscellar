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
    
    purchase_receivables = []

    #for pr in purchase_receivables
    for pr in bulk_purchase.purchase_receivables
      purchase_receivables << pr.id
    end

    post bulk_purchases_path, purchase_receivables: purchase_receivables    
    assert :success
    assert_template 'bulk_purchases/create'
    purchase_receivables = assigns(:purchase_receivables)
    assert_not_nil purchase_receivables
    puts "number of purchase receivables: #{purchase_receivables.count}"
    
    bulk_purchase = assigns(:bulk_purchase)
    assert_not_nil bulk_purchase
    puts "number of prs in this bp: #{bulk_purchase.purchase_receivables.to_a.count.to_s}"
    puts "number of bulk_purchases in the database: #{BulkPurchase.count.to_s}"

  end
end
