require 'bulk_buy_helper'

class RtauthorizationssTest < BulkBuyer
  
  def setup
    super  
  end

  test "rtf items should charge user funds account in a batch" do

    nuke_all_postings    

    assert_equal 0, Rtpurchase.count

    #this part isn't central to the setup. when we're doing the actual testing we want to make sure that past transactions don't get resurrected...
    #charged twice or in any way involved what will be the present transaction. so here we're going to do a normal posting/order/authroization/fill/purchase
    #cycle. then when we do it again we'll make sure this first cycle doesn't get involved in the second transaction
    april1 = Time.zone.local(2017, 4, 1)
    travel_to april1

    april14 = Time.zone.local(2017, 4, 14)
    producer1 = create_producer(name = "producer1", email = "producer1@p.com")
    posting_beets = create_posting(producer1, price = 19.99, product = Product.create(name: "Beets"), unit = nil, delivery_date = april14, order_cutoff = nil, units_per_case = nil, frequency = 1)

    #customer orders and auths some product    
    customer = create_new_customer
    ti_beets_customer = create_tote_item(customer, posting_beets, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(customer)

    #customer orders and auths some product
    customer2 = create_new_customer(name = "customer2", email = "customer2@c.com")
    ti_beets_customer2 = create_tote_item(customer2, posting_beets, quantity = 1, frequency = nil, roll_until_filled = true)
    create_rt_authorization_for_customer(customer2)

    #now order cutoff for beets
    travel_to posting_beets.order_cutoff
    RakeHelper.do_hourly_tasks

    #now fill the orders
    fully_fill_creditor_order(posting_beets.creditor_order)

    #now process payments
    travel_to posting_beets.delivery_date + 22.hours
    RakeHelper.do_hourly_tasks

    #verify 2 purchase objects and both tote items are FILLED
    assert_equal 2, Rtpurchase.count
    assert ti_beets_customer.reload.state?(:FILLED)
    assert ti_beets_customer2.reload.state?(:FILLED)

    #now we move on to the real test situation and, when done, verify that the above transactions don't come in to play

    may1 = Time.zone.local(2017, 5, 1)
    travel_to may1
    
    milk_oc = may1 + 32.hours #this is tuesday 8am
    milk_dd = may1 + 3.days #thursday delivery
    posting_milk = create_posting(producer1, price = 7.77, product = Product.create(name: "Milk"), unit = nil, delivery_date = milk_dd, order_cutoff = milk_oc, units_per_case = nil, frequency = 1)
   
    producer2 = create_producer(name = "producer2", email = "producer2@p.com")
    chicken_oc = may1 + 1.day + 22.hours #tuesday 10pm
    chicken_dd = may1 + 6.days #sunday delivery    
    posting_chicken = create_posting(producer2, price = 20.83, product = Product.create(name: "Chicken"), unit = nil, delivery_date = chicken_dd, order_cutoff = chicken_oc, units_per_case = nil, frequency = 1)

    #user adds milk and chicken as rtfs    
    ti_milk = create_tote_item(customer, posting_milk, quantity = 1, frequency = nil, roll_until_filled = true)
    ti_chicken = create_tote_item(customer, posting_chicken, quantity = 1, frequency = nil, roll_until_filled = true)
    #user authorizes milk and chicken
    auth_milk_chicken = create_rt_authorization_for_customer(customer)

    assert_equal auth_milk_chicken, ti_milk.reload.rtauthorization
    assert_equal auth_milk_chicken, ti_chicken.reload.rtauthorization

    #now milk and chicken order cutoffs hit
    travel_to milk_oc
    RakeHelper.do_hourly_tasks
    travel_to chicken_oc
    RakeHelper.do_hourly_tasks

    #now milk fills on thursday
    fully_fill_creditor_order(posting_milk.creditor_order)

    #verify there are still only 2 purchases in the db
    assert_equal 2, Rtpurchase.count

    #we travel to funds processing time on Thursday and no funds should move since user has another item arriving later in the week
    travel 10.hours
    RakeHelper.do_hourly_tasks
    assert_equal 2, Rtpurchase.count

    #make the butter ad
    may11 = Time.zone.local(2017, 5, 11)
    butter_oc = may11 - 2.days + 8.hours    
    posting_butter = create_posting(producer1, price = 9.7, product = Product.create(name: "Butter"), unit = nil, delivery_date = may11, order_cutoff = butter_oc, units_per_case = nil, frequency = 1)

    #make the pork ad
    may14 = Time.zone.local(2017, 5, 14)
    producer3 = create_producer(name = "producer3", email = "producer3@p.com")
    posting_pork = create_posting(producer3, price = 28, product = Product.create(name: "Pork"), unit = nil, delivery_date = may14, order_cutoff = may14 - 2.days, units_per_case = nil, frequency = 1)    

    #go to may 5 at noon and make another authorization
    travel_to posting_milk.delivery_date + 1.day + 12.hours
    ti_butter = create_tote_item(customer, posting_butter, quantity = 1, frequency = nil, roll_until_filled = true)
    auth_butter = create_rt_authorization_for_customer(customer)

    #you might be thinking there should only be 3 items in this auth. think again. it's friday right now...the chicken commitment zone, this means the chicken series
    #has one item in state committed and another in authorized for the next posting acting on the assumption the committed item won't fill this sunday
    assert_equal 4, auth_butter.reload.tote_items.count

    assert ti_butter.reload.state?(:AUTHORIZED)    
    assert ti_chicken.reload.state?(:COMMITTED)
    assert ti_milk.reload.state?(:FILLED)

    assert_equal auth_butter, ti_butter.reload.rtauthorization
    assert_equal auth_butter, ti_chicken.reload.rtauthorization
    assert_equal auth_butter, ti_milk.reload.rtauthorization

    assert_equal auth_butter, ti_butter.subscription.rtauthorization
    assert_equal auth_butter, ti_chicken.subscription.rtauthorization

    #this is friday. milk filled yesterday. when milk filled it should have turned this rtf subscription off so this sx shouldn't be authorized on the butter auth
    assert_not_equal auth_butter, ti_milk.subscription.rtauthorization
    assert_not ti_milk.subscription.on

    #go to sunday may 7, fill the chicken ad
    fully_fill_creditor_order(posting_chicken.creditor_order)

    #now auth the pork
    travel 1.minute
    ti_pork = create_tote_item(customer, posting_pork, quantity = 1, frequency = nil, roll_until_filled = true)
    auth_pork = create_rt_authorization_for_customer(customer)    

    #why is this still 4? the last check on auth_butter like this was 4 also. the reason is because in between the last check the chicken filled. this caused
    #the item for next week's chicken posting to transition to REMOVED so that when the pork auth happened the REMOVED item wasn't included in the auth. so
    #decrement the tote item count for that. but then increment it to account for the newly added item...namely, pork
    assert_equal 4, auth_pork.tote_items.count
    assert ti_pork.reload.state?(:AUTHORIZED)    
    assert ti_butter.reload.state?(:AUTHORIZED)    
    assert ti_chicken.reload.state?(:FILLED)
    assert ti_milk.reload.state?(:FILLED)
    assert_equal auth_pork, ti_pork.rtauthorization
    assert_equal auth_pork, ti_butter.rtauthorization
    assert_equal auth_pork, ti_chicken.rtauthorization
    assert_equal auth_pork, ti_milk.rtauthorization

    assert_equal 2, auth_pork.subscriptions.count
    assert_equal auth_pork, ti_pork.subscription.rtauthorization
    assert_equal auth_pork, ti_butter.subscription.rtauthorization

    travel_to posting_chicken.delivery_date + 22.hours
    RakeHelper.do_hourly_tasks

    #now there should be another purchase
    assert_equal 3, Rtpurchase.count
    #and it should be based off the pork authorization
    assert_equal auth_pork, Rtpurchase.last.purchase_receivables.first.tote_items.first.rtauthorization

    #this purchase should have been for the milk and the chicken
    assert_equal 2, Rtpurchase.last.purchase_receivables.count
    assert_equal 1, Rtpurchase.last.purchase_receivables.first.tote_items.count
    ti1 = Rtpurchase.last.purchase_receivables.first.tote_items.first
    #milk
    assert_equal ti_milk, ti1

    assert_equal 1, Rtpurchase.last.purchase_receivables.last.tote_items.count
    ti2 = Rtpurchase.last.purchase_receivables.last.tote_items.first
    #chicken
    assert_equal ti_chicken, ti2

  end

  test "rtpurchase object should be created" do

    nuke_all_tote_items
    assert_equal 0, ToteItem.count    
    assert_equal 0, BulkPurchase.count
    assert_equal 0, Rtpurchase.count
    setup_basic_subscription_through_delivery
    assert_equal 2, Posting.count    
    dt = Posting.first.delivery_date
    travel_to Time.zone.local(dt.year, dt.month, dt.day, 22, 0)
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
    assert_nil flash[:danger]
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