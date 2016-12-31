require 'test_helper'
require 'utility/rake_helper'
require 'bulk_buy_helper'

class RtauthorizationssTest < BulkBuyer
  
  def setup
    super  
  end

  test "rtpurchase object should be created" do

    nuke_all_tote_items
    assert_equal 0, ToteItem.count    
    assert_equal 0, BulkPurchase.count
    assert_equal 0, Rtpurchase.count
    setup_basic_subscription_through_delivery
    assert_equal 2, Posting.count    
    travel_to Posting.first.delivery_date + 22.hours    
    RakeHelper.do_hourly_tasks
    assert_equal 1, BulkPurchase.count
    assert_equal 1, Rtpurchase.count
    bp = BulkPurchase.first

    #this line is really what the test is all about. in rtpurchase.rb's .go method theres an 'if success?'
    #line. right after that there's a save. that save was added because without it the 'tote_items = ' line
    #was returning zero results so payment_processor_fee_withheld_from_producer was evaluating to zero
    assert bp.payment_processor_fee_withheld_from_producer > 0

    travel_back

  end

  test "purchase should succeed despite unfinished billing agreement after one time authorization" do
    
    c = users(:c_one_tote_item)
    tote_item = c.tote_items.first
    posting = tote_item.posting
    posting.reload

    gross_tote_item_value = get_gross_item(tote_item)

    #do one time checkout and authorization
    auth = create_authorization_for_customer(c)

    #do billing agreement checkout (do not authorize)    
    checkouts_count = Checkout.count
    post checkouts_path, params: {amount: gross_tote_item_value, use_reference_transaction: "1"}
    assert_equal nil, flash[:danger]
    assert_equal checkouts_count + 1, Checkout.count
    assert_equal true, Checkout.last.is_rt

    #let nature take its course. purchase should occur off the first checkout
    travel_to tote_item.posting.order_cutoff - 1.hour

    100.times do

      top_of_hour = Time.zone.now.min == 0
      is_noon_hour = Time.zone.now.hour == 12

      RakeHelper.do_hourly_tasks

      if is_noon_hour && top_of_hour        

        is_delivery_date = Time.zone.now.midnight == posting.delivery_date

        if is_delivery_date
          #ok, food arrived. now fill some orders        
          fill_all_tote_items = true            
          simulate_order_filling_for_postings([posting], fill_all_tote_items)          
        end        

      end      

      travel 1.hour

    end

    travel_back

    #verify purchase went through ok (or, well, a proxy thereof at least)
    assert_equal PurchaseReceivable.last.id, tote_item.purchase_receivables.last.id
    assert PurchaseReceivable.last.amount > 0
    assert_equal PurchaseReceivable.last.amount, PurchaseReceivable.last.amount_purchased
    assert gross_tote_item_value > 0
    tote_item.reload
    assert_equal get_gross_item(tote_item, filled = true), PurchaseReceivable.last.amount

  end

end