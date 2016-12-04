require 'test_helper'
require 'utility/rake_helper'
require 'bulk_buy_helper'

class RtauthorizationssTest < BulkBuyer
  
  def setup
    super  
  end

  test "purchase should succeed despite unfinished billing agreement after one time authorization" do
    
    c = users(:c_one_tote_item)
    tote_item = c.tote_items.first
    posting = tote_item.posting

    #cheating. i'm scabbing some late_adds_allowed code in here so i can move fast after having added this feature.
    #if the feature works this test purchase should go through just fine even though the posting removes all
    #ADDED tote items when it transitions from OPEN to COMMITMENTZONE
    assert posting.late_adds_allowed
    posting.update(late_adds_allowed: false)
    posting.reload
    assert_not posting.late_adds_allowed

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

    posting.update(late_adds_allowed: true)

  end

end