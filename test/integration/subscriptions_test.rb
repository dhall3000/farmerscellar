require 'test_helper'

class SubscriptionsTest < ActionDispatch::IntegrationTest
  
  def setup

  end  

  #to add new product/posting to this farmer create a producer_product_commission

  test "subscriptions" do    

    postings = setup_posting_recurrences
    posting_recurrences = get_posting_recurrences(postings)

    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]
    add_subscription(user, apples_posting, quantity, frequency)

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    num_days = 20
    time_loop(posting_recurrences, num_days)

    num_c17_deliveries = num_days / (frequency * 7)
    #however many deliveries there are this user should have 1 more because after the test stops there whould be 
    #remaining a single tote item in the AUTHORIZED state
    assert_equal num_c17_deliveries + 1, ToteItem.where(user_id: user.id).count
    assert_equal num_c17_deliveries, ToteItem.where(user_id: user.id, state: ToteItem.states[:FILLED]).count
    assert_equal 1, ToteItem.where(user_id: user.id, state: ToteItem.states[:AUTHORIZED]).count

    delivery_cost = (quantity * apples_posting.price).round(2)
    total_cost = (delivery_cost * num_c17_deliveries).round(2)

    sum = 0

    UserPurchaseReceivable.where(user: user).each do |upr|
      rtp = upr.purchase_receivable.rtpurchases.last
      sum += rtp.gross_amount
    end
    
    assert_equal total_cost, sum

    #TODO:
    #-make sure payment payables are in proper amounts
    #-verify proper emails sent, with proper text
    #-step through the whole code path and look for trouble. yes, this is a big task, but it's a good thing to do.

  end

  def get_posting_recurrences(postings)
    
    posting_recurrences = []
    postings.each do |posting|
      posting_recurrences << posting.posting_recurrence
    end

    return posting_recurrences

  end

  def add_subscription(user, posting, quantity, frequency)
    
    log_in_as(user)
    post user_dropsites_path, user_dropsite: {dropsite_id: dropsites(:dropsite1).id}

    post tote_items_path, tote_item: {
      quantity: quantity,
      price: posting.price,
      state: ToteItem.states[:ADDED],
      posting_id: posting.id,
      user_id: user.id,
      subscription_frequency: frequency
    }

    post checkouts_path, use_reference_transaction: 1
    checkout = assigns(:checkout)
    post rtauthorizations_create_path, token: checkout.token

  end

  def setup_posting_recurrences

    postings = []
    
    farmer = users(:f_subscriptions)
    log_in_as(farmer)

    #apples, deliverable weekly on mondays
    delivery_date = next_day_of_week_after(Time.zone.now, 1, 7)    
    post postings_path, posting: {
      description: "apples description",
      quantity_available: 100,
      price: 1.99,
      user_id: farmer.id,
      product_id: products(:apples).id,
      unit_category_id: unit_categories(:weight).id,
      unit_kind_id: unit_kinds(:pound).id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days,
      posting_recurrence: {frequency: 1, on: true}
    }
    postings << assigns(:posting)

    #lettuce, deliverable weekly on wednesdays
    delivery_date = next_day_of_week_after(Time.zone.now, 3, 7)
    post postings_path, posting: {
      description: "lettuce description",
      quantity_available: 100,
      price: 2.99,
      user_id: farmer.id,
      product_id: products(:lettuce).id,
      unit_category_id: unit_categories(:weight).id,
      unit_kind_id: unit_kinds(:pound).id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days,
      posting_recurrence: {frequency: 1, on: true}
    }
    postings << assigns(:posting)

    #tomatos, deliverable weekly on fridays
    delivery_date = next_day_of_week_after(Time.zone.now, 5, 7)
    post postings_path, posting: {
      description: "tomato description",
      quantity_available: 100,
      price: 3.99,
      user_id: farmer.id,
      product_id: products(:tomato).id,
      unit_category_id: unit_categories(:weight).id,
      unit_kind_id: unit_kinds(:pound).id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days,
      posting_recurrence: {frequency: 1, on: true}
    }
    postings << assigns(:posting)

    return postings

  end

  def time_loop(posting_recurrences, num_days)
    
    current_time = Time.zone.now.midnight
    end_minute = Time.zone.now.midnight + num_days.days

    travel_to current_time

    while Time.zone.now < end_minute
      top_of_hour = Time.zone.now.min == 0

      if top_of_hour
        RakeHelper.do_hourly_tasks        
      end

      #do fills for any postings for whom it's presently noon on delivery day
      if Time.zone.now == Time.zone.today.noon

        #do fills for any postings for whom it's presently noon on delivery day        
        posting_recurrences.each do |pr|
          pr.reload
          pr.postings.each do |posting|          
            posting.reload
            if posting.delivery_date.midnight == Time.zone.now.midnight
              if posting.total_quantity_authorized_or_committed > 0
                puts Time.zone.now.strftime("%A %B %d")
                #it is now noon on delivery_date of this posting so do some fills
                log_in_as(users(:a1))
                post postings_fill_path, posting_id: posting.id, quantity: posting.total_quantity_authorized_or_committed
              end              
            end
          end        
        end

      end

      travel 60.minutes
      current_time = Time.zone.now
            
    end
       
    travel_back

  end

  def next_day_of_week_after(reference_date, wday, num_days_after)

    date = (reference_date + num_days_after.days).midnight
    
    while date.wday != wday
      date += 1.day
    end

    return date        

  end

end
