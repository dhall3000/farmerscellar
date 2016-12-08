require 'test_helper'
require 'utility/rake_helper'
require 'integration_helper'

class SubscriptionsTest < IntegrationHelper
  include ActionView::Helpers::DateHelper 
  
  def setup
    @on = false
    @farmer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)    
    @posting = postings(:postingf1apples)
  end  

  test "should generate tote item if when a bi weekly subscription is paused producer changes delivery day then user unpauses subscription" do
    nuke_all_postings

    #establish weekly posting recurrence on wednesdays
    producer = create_producer("producer1", "producer1@p.com")        
    jan6 = Time.zone.local(2016, 1, 6)
    delivery_date = jan6
    order_cutoff = delivery_date - 2.days

    #jump to first commitment zone in the series
    travel_to order_cutoff
    #Monday Jan 4
    posting = create_posting(producer, 2.50, product = nil, unit = nil, delivery_date, order_cutoff, units_per_case = 1)
    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting_recurrence.postings << posting
    posting_recurrence.save
    #current posting: Wednesday Jan 6
    #generate the pr's first posting
    assert_equal 1, posting_recurrence.postings.count    
    RakeHelper.do_hourly_tasks
    #current posting: Wednesday Jan 13
    assert_equal 2, posting_recurrence.postings.count
    assert_equal Time.zone.local(2016, 1, 13), posting_recurrence.reload.postings.last.delivery_date
    #create bi-weekly subscription
    jane = create_user("jane", "jane@j.com")
    subscription = add_subscription(jane, posting_recurrence.reload.current_posting, quantity = 2, frequency = 2)

    assert_equal 1, subscription.tote_items.count
    assert_equal Time.zone.local(2016, 1, 13), subscription.tote_items.last.posting.delivery_date


    travel 7.days
    #Monday Jan 11
    assert_equal Time.zone.local(2016, 1, 11), Time.zone.now
    RakeHelper.do_hourly_tasks
    #current posting: Wednesday Jan 20
    assert_equal 3, posting_recurrence.postings.count
    assert_equal Time.zone.local(2016, 1, 20), posting_recurrence.reload.postings.last.delivery_date
    assert_equal 1, subscription.reload.tote_items.count

    travel_to Time.zone.local(2016, 1, 14)
    #Thursday Jan 14
    #change the delivery day to thursday (from wednesday)    
    assert posting_recurrence.reload.change_delivery_day?(new_wday = 4)
    assert_equal Time.zone.local(2016, 1, 21), posting_recurrence.reload.current_posting.delivery_date


    subscription.pause
    
    count = 0
    while count < 4
      travel_to posting_recurrence.reload.current_posting.order_cutoff
      RakeHelper.do_hourly_tasks            
      count += 1
      assert_equal 3 + count, posting_recurrence.reload.postings.count      
    end

    #Monday Jan 8
    assert_equal Time.zone.local(2016,2,8), Time.zone.now
    #current posting: Feb 18
    assert_equal Time.zone.local(2016,2,18), posting_recurrence.reload.current_posting.delivery_date
    
    #verify still same # of items on the paused sx
    assert_equal 1, subscription.reload.tote_items.count

    #now go to the friday after the current
    travel 4.days
    #unpause subxcription
    subscription.reload.unpause
    #verify the unpause generated a tote time for the upcoming producer delivery
    assert_equal 2, subscription.reload.tote_items.count
    assert subscription.tote_items.last.state?(:AUTHORIZED)
    #verify just-added tote item is for the current_posting
    assert_equal Time.zone.local(2016,2,18), subscription.tote_items.last.posting.delivery_date
    assert_equal posting_recurrence.reload.current_posting.delivery_date, subscription.tote_items.last.posting.delivery_date

    #go to current_posting order cutoff
    travel_to posting_recurrence.reload.current_posting.order_cutoff
    #Mon Feb 15
    assert_equal Time.zone.local(2016,2,15), posting_recurrence.reload.current_posting.order_cutoff
    RakeHelper.do_hourly_tasks

    #verify new posting created for feb 25 delivery
    assert_equal Time.zone.local(2016,2,25), posting_recurrence.reload.current_posting.delivery_date

    #verify a tote item was not generated for this latest posting...
    assert_equal 2, subscription.reload.tote_items.count
    #...and thus the last item in the sx should be the same as it was
    assert_equal Time.zone.local(2016,2,18), subscription.tote_items.last.posting.delivery_date

    travel_back
  end

  test "when weekly producer changes wday with a bi weekly subscriber should create tote item spaced roughly two weeks apart" do

    nuke_all_postings

    #establish weekly posting recurrence on wednesdays
    producer = create_producer("producer1", "producer1@p.com")        
    jan6 = Time.zone.local(2016, 1, 6)
    delivery_date = jan6
    order_cutoff = delivery_date - 2.days

    #jump to first commitment zone in the series
    travel_to order_cutoff
    #Monday Jan 4
    posting = create_posting(producer, 2.50, product = nil, unit = nil, delivery_date, order_cutoff, units_per_case = 1)
    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting_recurrence.postings << posting
    posting_recurrence.save
    #current posting: Wednesday Jan 6
    #generate the pr's first posting
    assert_equal 1, posting_recurrence.postings.count    
    RakeHelper.do_hourly_tasks
    #current posting: Wednesday Jan 13
    assert_equal 2, posting_recurrence.postings.count
    assert_equal Time.zone.local(2016, 1, 13), posting_recurrence.reload.postings.last.delivery_date
    #create bi-weekly subscription
    jane = create_user("jane", "jane@j.com")
    subscription = add_subscription(jane, posting_recurrence.reload.current_posting, quantity = 2, frequency = 2)
    
    assert_equal 1, subscription.tote_items.count
    assert_equal Time.zone.local(2016, 1, 13), subscription.tote_items.last.posting.delivery_date


    travel 7.days
    #Monday Jan 11
    assert_equal Time.zone.local(2016, 1, 11), Time.zone.now
    RakeHelper.do_hourly_tasks
    #current posting: Wednesday Jan 20
    assert_equal 3, posting_recurrence.postings.count
    assert_equal Time.zone.local(2016, 1, 20), posting_recurrence.reload.postings.last.delivery_date
    assert_equal 1, subscription.reload.tote_items.count

    travel_to Time.zone.local(2016, 1, 14)
    #Thursday Jan 14
    #change the delivery day to thursday (from wednesday)    
    assert posting_recurrence.reload.change_delivery_day?(new_wday = 4)
    assert_equal Time.zone.local(2016, 1, 21), posting_recurrence.reload.current_posting.delivery_date




    travel_to posting_recurrence.reload.current_posting.order_cutoff
    #Monday Jan 18
    assert_equal Time.zone.local(2016, 1, 18), Time.zone.now

    RakeHelper.do_hourly_tasks
    assert_equal 4, posting_recurrence.reload.postings.count
    assert_equal Time.zone.local(2016, 1, 28), posting_recurrence.reload.current_posting.delivery_date
    assert_equal 2, subscription.reload.tote_items.count
    assert_equal Time.zone.local(2016, 1, 28), subscription.tote_items.last.posting.delivery_date

    #right after subscription's last delivery producer changes delivery day to thursday
    #subscription should change days with pr but stay on schedule 

    travel_back

  end

  test "should give immediate next delivery date as skip date option" do

    #NOT COMMITTED, DON'T SKIP

    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #save the immediate next delivery date (INDD)
    immediate_next_delivery_date = ToteItem.where(user_id: user.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, subscription

    #get the skip_dates structure
    log_in_as(user)
    #view the index
    get subscriptions_path
    #get the computed skip dates
    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 1

    #verify the INDD is in the skip_dates structure
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #fast forward to indd's order cutoff
    posting = do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    next_ti = subscription.reload.latest_delivery_date_item
    #verify INDD not skipped. here (order cutoff) it should be COMMITTED...
    assert indd.reload.state?(:COMMITTED)
    #do delivery
    go_to_delivery_day_and_fill_posting(posting)
    #verify INDD got filled
    assert indd.reload.state?(:FILLED)
    assert indd.fully_filled?

    #verify next not skipped
    posting = do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    go_to_delivery_day_and_fill_posting(posting)
    #next should be FILLED    
    assert next_ti.reload.state?(:FILLED)

    #first and second FILLED ti's should match the 2 skip dates given earlier
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]
    assert_equal next_ti.posting.delivery_date, skip_dates[1][:date]

    #first and second ti's should not be the same object
    assert_not indd == next_ti
    #first and second ti's should be separated by 7 days
    assert_equal distance_of_time_in_words(7.days), distance_of_time_in_words(next_ti.posting.delivery_date - indd.posting.delivery_date)

    travel_back

  end

  test "should skip immediate next delivery date" do

    #NOT COMMITTED, ATTEMPT SKIP
    
    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #save the immediate next delivery date (INDD)
    immediate_next_delivery_date = ToteItem.where(user_id: user.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, subscription

    #get the skip_dates structure
    log_in_as(user)
    #view the index
    get subscriptions_path
    #get the computed skip dates
    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 1

    #verify the INDD is in the skip_dates structure
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #specify skip INDD
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }

    #verify INDD is REMOVED (i.e. skipped)
    assert indd.reload.state?(:REMOVED)
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)

    #go one hour in to the commitment zone, then verify INDD is no longer displayed in skip dates
    travel 1.hour
    log_in_as(user)
    #view the index
    get subscriptions_path
    skip_dates = assigns(:skip_dates)        
    assert skip_dates.count > 0
    #the person specified to skip, then let the order cutoff hit, then views their skip date options. at this point it is
    #not an option for them to 'unskip' INDD so we don't even show that in skip_dates. therefore, the first displayed
    #skip date should be 7 days after INDD    
    assert_equal distance_of_time_in_words(7.days), distance_of_time_in_words(skip_dates[0][:date] - indd.posting.delivery_date)

    go_to_delivery_day_and_fill_posting(indd.posting)

    #we should now be on the delivery day of the INDD
    assert_equal Time.zone.now.midnight, indd.posting.delivery_date
    #the 'next' ti should have been generated for the subscription
    assert_equal 2, subscription.reload.tote_items.count
    #this 'next' ti should be out ahead of INDD
    assert subscription.tote_items.last.posting.delivery_date > indd.posting.delivery_date
    assert_equal distance_of_time_in_words(7.days), distance_of_time_in_words(subscription.tote_items.last.posting.delivery_date - indd.posting.delivery_date)
    #assert INDD really is REMOVED
    assert indd.reload.state?(:REMOVED)

    #verify 'next' gets filled
    posting = subscription.reload.posting_recurrence.current_posting
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    go_to_delivery_day_and_fill_posting(posting)

    #verify there's another tote item generated
    assert_equal 3, subscription.reload.tote_items.count
    #verify the first is REMOVED
    assert subscription.tote_items.first.state?(:REMOVED)
    #verify the second is FILLED
    assert subscription.tote_items.second.state?(:FILLED)
    #verify the third is AUTHORIZED
    assert subscription.tote_items.third.state?(:AUTHORIZED)

    travel_back

  end

  test "item nuked from tote should show checked skip date" do

    #Say that you have a subscription with an item in the tote. Then if you go into the tote and nuke
    #the item then after that go into the subscription index what you will see is a skip date that is unchecked.
    #This is nonsensical. It should be checked.

    nuke_all_postings
    posting = setup_posting_recurrence(product = products(:apples), frequency = 2)
    quantity = 2
    frequency = 4 #every 8 weeks
    user = create_user("jane", "jane@j.com")
    subscription = add_subscription(user, posting, quantity, frequency)

    #user should get FILLED on the very first posting in the series
    assert_equal 1, user.reload.tote_items.count
    ti = user.tote_items.first
    assert ti.state?(:AUTHORIZED)

    #go in to the tote, nuke the item from the tote
    log_in_as(user)
    delete tote_item_path(id: ti.id)
    assert ti.reload.state?(:REMOVED)
    
    #pull down the skip dates
    get subscriptions_path(end_date: (Time.zone.now + 10.weeks).to_s)
    skip_dates = assigns(:skip_dates)      

    #verify the skip date for the appropriate date is checked while others are not
    assert_equal ti.posting.delivery_date, skip_dates[0][:date]
    assert skip_dates[0][:skip]

    assert_equal ti.posting.delivery_date + (8 * 7).days, skip_dates[1][:date]
    assert_not skip_dates[1][:skip]

    travel_back

  end

  test "skip dates programming for oddball recurrence and subscription schedules" do

    #description: we're going to set up aposting recurrence of every other week and
    #subscription of every 8 weeks. we're just going to pick along through this and
    #verify it's doing the right thing

    nuke_all_postings
    posting = setup_posting_recurrence(product = products(:apples), frequency = 2)
    quantity = 2
    frequency = 4 #every 8 weeks
    user = create_user("jane", "jane@j.com")
    subscription = add_subscription(user, posting, quantity, frequency)

    #user should get FILLED on the very first posting in the series
    assert_equal 1, user.reload.tote_items.count

    user_first_item = user.tote_items.first

    #then user should not get filled for the next four producer deliveries, so that
    #user's next delivery is 8 weeks from the first
    count = 0
    while count < 4

      posting = subscription.reload.posting_recurrence.current_posting
      do_current_posting_order_cutoff_tasks(subscription.reload.posting_recurrence)
      travel 1.hour

      if count < 3
        #for the first three producer deliveries a user item should not be added
        assert_equal 1, user.reload.tote_items.count
      end

      go_to_delivery_day_and_fill_posting(posting)

      if count < 3
        #for the first three producer deliveries the user's only item should remain FILLED
        assert user.reload.tote_items.last.state?(:FILLED)
      end
      
      #get the skip_dates structure
      log_in_as(user)
      get subscriptions_path
      skip_dates = assigns(:skip_dates)      

      #user's next available skip date should be 8 weeks from their first delivery
      assert_equal user_first_item.posting.delivery_date + (8 * 7).days, skip_dates[0][:date]

      count += 1

    end

    #we should now be 6 weeks from user's first delivery (which is the same as 2 weeks away from user's next delivery)
    assert_equal user_first_item.posting.delivery_date + (6 * 7).days + 12.hours, Time.zone.now

    #user should have 2 tote items now and the 2nd should be AUTHORIZED
    assert_equal 2, user.reload.tote_items.count
    assert user.tote_items.last.state?(:AUTHORIZED)

    #skipping this second delivery now should cause this 2nd/last item to transition to REMOVED
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }    
    assert_equal 2, user.reload.tote_items.count
    assert user.tote_items.last.state?(:REMOVED)

    #unskipping should create a 3rd item which should be in the AUTHORIZED state and have correct date
    post subscriptions_skip_dates_path, params: 
    {
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }
    assert_equal 3, user.reload.tote_items.count
    assert user.tote_items.last.state?(:AUTHORIZED)

    #going 1 hour past order cutoff of current posting should make it so first skip date remains 8 weeks from 1st delivery
    do_current_posting_order_cutoff_tasks(subscription.reload.posting_recurrence)
    travel 1.hour
    log_in_as(user)
    get subscriptions_path(end_date: user_first_item.posting.delivery_date + 20.weeks)
    skip_dates = assigns(:skip_dates)          
    assert_equal user_first_item.posting.delivery_date + (8 * 7).days, skip_dates[0][:date]
    #but this 1st skip date should be disabled because we're after order cutoff
    assert skip_dates[0][:disabled]
    #and second skip date is 16 weeks from 1st delivery
    assert_equal user_first_item.posting.delivery_date + (16 * 7).days, skip_dates[1][:date]

    travel_back

  end

  test "should skip immediate next delivery date and next then unskip only indd" do

    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #save the immediate next delivery date (INDD)
    immediate_next_delivery_date = ToteItem.where(user_id: user.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, subscription

    #get the skip_dates structure
    log_in_as(user)
    #view the index
    get subscriptions_path
    #get the computed skip dates
    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 1

    #verify the INDD is in the skip_dates structure
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #specify skip INDD and next
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s, skip_dates.second[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }

    assert indd.reload.state?(:REMOVED)

    #'unskip' indd only (not 'next', the one after indd)
    assert_equal 1, user.reload.tote_items.count
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.second[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }
    #a new item should have been added
    assert_equal 2, user.reload.tote_items.count
    assert_equal indd.posting.delivery_date, user.tote_items.last.posting.delivery_date
    assert user.tote_items.first.state?(:REMOVED)
    assert user.tote_items.last.state?(:AUTHORIZED)

    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)

    #go one hour in to the commitment zone, then verify INDD is displayed in skip dates but with disabled: true
    travel 1.hour
    log_in_as(user)

    #view the index
    get subscriptions_path
    skip_dates = assigns(:skip_dates)        
    #at this point there should be three skip dates. the first should have disabled: true because it's in the commitment zone
    assert_equal 3, skip_dates.count
    assert skip_dates[0][:disabled]
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #there should be 2 items. the first should be REMOVED, 2nd COMMITTED and these two should have the same delivery date
    #because the user skipped and then immediately unskipped   
    assert_equal 2, user.reload.tote_items.count
    assert user.reload.tote_items.first.state?(:REMOVED)
    assert user.reload.tote_items.second.state?(:COMMITTED)
    assert_equal user.reload.tote_items.first.posting.delivery_date, user.reload.tote_items.last.posting.delivery_date
        
    go_to_delivery_day_and_fill_posting(indd.posting)

    #we should now be on the delivery day of the INDD
    assert_equal Time.zone.now.midnight, indd.posting.delivery_date
    #assert INDD really is REMOVED
    assert indd.reload.state?(:REMOVED)    
    assert user.reload.tote_items.first.state?(:REMOVED)
    #verify unskipped item got filled
    assert user.reload.tote_items.last.state?(:FILLED)

    #verify 'next' gets filled
    posting = subscription.reload.posting_recurrence.current_posting
    assert_equal 0, posting.reload.total_quantity_ordered_from_creditor
    assert posting.reload.state?(:OPEN)
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    assert posting.reload.state?(:CLOSED)

    #verify there's another tote item generated
    assert_equal 3, subscription.reload.tote_items.count
    #verify the first is REMOVED
    assert subscription.tote_items.first.state?(:REMOVED)
    #verify the second is FILLED
    assert subscription.tote_items.second.state?(:FILLED)
    #verify the third is AUTHORIZED
    assert subscription.tote_items.third.state?(:AUTHORIZED)
    #verify 2 week spacing between fills
    gap = subscription.tote_items.third.posting.delivery_date - subscription.tote_items.second.posting.delivery_date    
    assert_equal distance_of_time_in_words(14.days), distance_of_time_in_words(gap)

    travel_back

  end

  test "should skip immediate next delivery date and next then unskip only next" do

    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #save the immediate next delivery date (INDD)
    immediate_next_delivery_date = ToteItem.where(user_id: user.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, subscription

    #get the skip_dates structure
    log_in_as(user)
    #view the index
    get subscriptions_path
    #get the computed skip dates
    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 1

    #verify the INDD is in the skip_dates structure
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #specify skip INDD and next
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s, skip_dates.second[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }

    assert indd.reload.state?(:REMOVED)

    #'unskip' next (not INDD...the one after that)
    assert_equal 1, user.reload.tote_items.count
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }
    #a new item should not have been added
    assert_equal 1, user.reload.tote_items.count
    assert_equal indd.posting.delivery_date, user.tote_items.last.posting.delivery_date
    assert user.tote_items.last.state?(:REMOVED)

    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)

    #go one hour in to the commitment zone, then verify INDD is displayed in skip dates but with disabled: true
    travel 1.hour
    log_in_as(user)

    #view the index
    get subscriptions_path
    skip_dates = assigns(:skip_dates)        
    #at this point there should be 2 skip dates
    assert_equal 2, skip_dates.count
    
    #there should be 3 items. the first should be REMOVED, 2nd COMMITTED and these two should have the same delivery date
    #because the user skipped and then immediately unskipped   
    assert_equal 2, user.reload.tote_items.count
    assert user.reload.tote_items.first.state?(:REMOVED)
    assert user.reload.tote_items.second.state?(:AUTHORIZED)
        
    go_to_delivery_day_and_fill_posting(indd.posting)

    #we should now be on the delivery day of the INDD
    assert_equal Time.zone.now.midnight, indd.posting.delivery_date
    #assert INDD really is REMOVED
    assert indd.reload.state?(:REMOVED)

    #verify unskipped item got filled
    assert user.reload.tote_items.first.state?(:REMOVED)

    #verify 'next' gets filled
    posting = subscription.reload.posting_recurrence.current_posting
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    go_to_delivery_day_and_fill_posting(posting)

    #verify there's another tote item generated
    assert_equal 3, subscription.reload.tote_items.count
    #verify the first is REMOVED
    assert subscription.tote_items.first.state?(:REMOVED)
    #verify the second is FILLED
    assert subscription.tote_items.second.state?(:FILLED)
    #verify the third is AUTHORIZED
    assert subscription.tote_items.third.state?(:AUTHORIZED)

    travel_back

  end

  test "should unskip immediate next delivery date" do

    #Immediate Next Delivery Date (INDD) item should be as normal
    #before order cutoff, user specifies to skip the delivery
    #user specifies to 'unskip' delivery
    #order cutoff hits
    #skip date should be shown, unchecked, disabled
    #delivery should happen

    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #save the immediate next delivery date (INDD)
    immediate_next_delivery_date = ToteItem.where(user_id: user.id).first
    indd = immediate_next_delivery_date
    assert_equal indd.subscription, subscription

    #get the skip_dates structure
    log_in_as(user)
    #view the index
    get subscriptions_path
    #get the computed skip dates
    skip_dates = assigns(:skip_dates)
    assert skip_dates.count > 1

    #verify the INDD is in the skip_dates structure
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]

    #verify INDD item not committed
    assert_not indd.reload.state?(:COMMITTED)

    #specify skip INDD
    post subscriptions_skip_dates_path, params: 
    {
      skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s]},
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }

    assert indd.reload.state?(:REMOVED)

    #'unskip' INDD
    assert_equal 1, user.reload.tote_items.count

    post subscriptions_skip_dates_path, params: 
    {
      subscription_ids: [subscription.id.to_s],
      end_date: (skip_dates.first[:date] + 7.days).to_s
    }
    #a new item should have been added with the same delivery date as INDD
    assert_equal 2, user.reload.tote_items.count
    assert_equal indd.posting.delivery_date, user.tote_items.last.posting.delivery_date
    assert user.tote_items.last.state?(:AUTHORIZED)

    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)

    #go one hour in to the commitment zone, then verify INDD is displayed in skip dates but with disabled: true
    travel 1.hour
    log_in_as(user)

    #view the index
    get subscriptions_path
    skip_dates = assigns(:skip_dates)        
    #at this point there should be three skip dates. the first should have disabled: true because it's in the commitment zone
    assert_equal 3, skip_dates.count
    assert_equal true, skip_dates[0][:disabled]

    #there should be 3 items. the first should be REMOVED, 2nd COMMITTED and these two should have the same delivery date
    #because the user skipped and then immediately unskipped   
    assert_equal 3, user.reload.tote_items.count
    assert user.reload.tote_items.first.state?(:REMOVED)
    assert user.reload.tote_items.second.state?(:COMMITTED)
    #the 1st and 2nd items represent the skipped and then immediately unskipped items so they should have the same delivery date
    assert_equal user.reload.tote_items.first.posting.delivery_date, user.reload.tote_items.second.posting.delivery_date
    #and this, the 3rd item, was generated when we hit the order cutoff
    assert user.reload.tote_items.third.state?(:AUTHORIZED)
    
    go_to_delivery_day_and_fill_posting(indd.posting)

    #we should now be on the delivery day of the INDD
    assert_equal Time.zone.now.midnight, indd.posting.delivery_date
    #assert INDD really is REMOVED
    assert indd.reload.state?(:REMOVED)

    #verify unskipped item got filled
    assert user.reload.tote_items.second.state?(:FILLED)

    #verify 'next' gets filled
    posting = subscription.reload.posting_recurrence.current_posting
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    go_to_delivery_day_and_fill_posting(posting)

    #verify there's another tote item generated
    assert_equal 4, subscription.reload.tote_items.count
    #verify the first is REMOVED
    assert subscription.tote_items.first.state?(:REMOVED)
    #verify the second is FILLED
    assert subscription.tote_items.second.state?(:FILLED)
    #verify the third is AUTHORIZED
    assert subscription.tote_items.third.state?(:FILLED)
    assert subscription.tote_items.fourth.state?(:AUTHORIZED)

    travel_back

  end

  test "should not generate tote items for skip dates" do

    postings = setup_posting_recurrences
    
    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    num_tote_items = user.tote_items.count
    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #let nature take its course. purchase should occur off the first checkout
    travel_to tote_item.posting.order_cutoff    
    has_created_skip_dates = false

    30.times do

      RakeHelper.do_hourly_tasks

      user.reload

      #enter a skip date after one tote items has been generated
      if !has_created_skip_dates && (user.tote_items.count == (num_tote_items + 3))

        log_in_as(user)
        #view the index
        get subscriptions_path
        #get the computed skip dates
        skip_dates = assigns(:skip_dates)
        #send one of the skip dates back up to the controller to program in to the db
        post subscriptions_skip_dates_path, params: {skip_dates: {subscription.id.to_s => [skip_dates.third[:date].to_s]}, subscription_ids: [subscription.id.to_s], end_date: (skip_dates.third[:date] + 7.days).to_s}
        subscription.reload        
        has_created_skip_dates = true
      end

      travel 1.day

    end

    travel_back

    subscription.posting_recurrence.reload
    user.reload

    num_tote_items_generated = user.tote_items.count - num_tote_items
    assert num_tote_items_generated > 0
    num_tote_items_skipped = subscription.posting_recurrence.postings.count - subscription.tote_items.count
    assert_equal 1, num_tote_items_skipped
    assert_equal num_tote_items_generated, subscription.tote_items.count
    assert_equal num_tote_items + num_tote_items_generated, user.tote_items.count

  end

  test "should not generate tote items after subscription is paused" do

    postings = setup_posting_recurrences
    posting_recurrences = get_posting_recurrences(postings)

    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    frequency = 1
    apples_posting = postings[0]

    subscription = add_subscription(user, apples_posting, quantity, frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #let nature take its course. purchase should occur off the first checkout
    travel_to tote_item.posting.order_cutoff

    num_tote_items = user.tote_items.count
    pause_time = Time.zone.now - 1.year
    regular_tote_item_delivery_gap = 1.minute
    has_paused = false

    5.times do

      top_of_hour = Time.zone.now.min == 0
      is_noon_hour = Time.zone.now.hour == 12

      RakeHelper.do_hourly_tasks

      user.reload

      #pause the subscription after one tote item has been generated
      if !has_paused && !subscription.paused && (user.tote_items.count == (num_tote_items + 1))
        log_in_as(user)
        patch subscription_path(subscription), params: {subscription: { paused: "1", on: "1" }}
        subscription.reload
        assert subscription.paused
        pause_time = Time.zone.now
        regular_tote_item_delivery_gap = subscription.tote_items.last.posting.delivery_date - subscription.tote_items.first.posting.delivery_date
        has_paused = true
      end

      #unpause subscription one delivery cycle after pausing it
      if subscription.paused && (Time.zone.now == (pause_time + regular_tote_item_delivery_gap))
        patch subscription_path(subscription), params: {subscription: { paused: "0", on: "1" }}
        subscription.reload
        assert_not subscription.paused
      end

      travel_to subscription.posting_recurrence.current_posting.order_cutoff

    end

    travel_back

    user.reload
    assert_equal user.tote_items.count, num_tote_items + subscription.tote_items.count - 1
    assert_equal subscription.tote_items.count, apples_posting.posting_recurrence.postings.count
    gap = subscription.tote_items[1].posting.delivery_date - subscription.tote_items[0].posting.delivery_date
    assert_equal distance_of_time_in_words(7.days), distance_of_time_in_words(gap)

    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[0].state
    assert_equal ToteItem.states[:REMOVED], subscription.tote_items[1].state
    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[2].state
    gap = subscription.tote_items[2].posting.delivery_date - subscription.tote_items[0].posting.delivery_date    
    assert_equal distance_of_time_in_words(14.days), distance_of_time_in_words(gap)
    
    gap = subscription.tote_items[3].posting.delivery_date - subscription.tote_items[2].posting.delivery_date
    assert_equal distance_of_time_in_words(7.days), distance_of_time_in_words(gap)

  end

  test "should not generate tote items after subscription is turned off" do
    do_subscription_turn_off(posting_frequency = 1, subscription_frequency = 1)
  end

  test "should not generate tote items after subscription is turned off monthly recurrence" do
    do_subscription_turn_off(posting_frequency = 5, subscription_frequency = 1)
  end

  test "should not generate tote items after subscription is turned off monthly recurrence 2" do
    do_subscription_turn_off(posting_frequency = 5, subscription_frequency = 2)
  end

  def do_subscription_turn_off(posting_frequency, subscription_frequency)

    posting = create_posting(farmer = nil, price = 1.27, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, posting_frequency)

    user = users(:c17)
    assert_equal 0, ToteItem.where(user_id: user.id).count

    quantity = 2
    subscription_frequency = 1    

    subscription = add_subscription(user, posting, quantity, subscription_frequency)
    tote_item = subscription.tote_items.first

    assert_equal 1, ToteItem.where(user_id: user.id).count
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.where(user_id: user.id).first.state

    #let nature take its course. purchase should occur off the first checkout
    travel_to tote_item.posting.order_cutoff

    num_tote_items = user.tote_items.count
    pause_time = Time.zone.now - 1.year
    regular_tote_item_delivery_gap = 1.minute
    has_paused = false

    110.times do

      top_of_hour = Time.zone.now.min == 0
      is_noon_hour = Time.zone.now.hour == 12

      RakeHelper.do_hourly_tasks

      user.reload

      #turn the subscription off after one tote item has been generated
      if subscription.on && user.tote_items.count == (num_tote_items + 1)
        log_in_as(user)
        patch subscription_path(subscription), params: {subscription: { paused: "0", on: "0" }}
        subscription.reload
        assert_not subscription.on        
      end

      travel 1.day

    end

    travel_back

    posting.reload
    user.reload
    assert_equal num_tote_items + 1, user.tote_items.count

    #as of this writing only two items should have been generated in this series. they should be without gap (i.e. 7 day spacing)
    #right at the beginning of the posting recurrence series. then the turn_off method gets called so their shoudl be no further
    #tote items. but the pr should keep chugging so there should be a big gap between the last posting in the pr series vs the ti series
    actual_tote_items_gap = subscription.tote_items[1].posting.delivery_date - subscription.tote_items[0].posting.delivery_date    
    actual_tote_item_postings_gap = posting.posting_recurrence.postings.last.delivery_date - subscription.tote_items.last.posting.delivery_date

    if posting_frequency > 0 && posting_frequency < 5      
      assert_equal distance_of_time_in_words((7 * posting_frequency * subscription_frequency).days), distance_of_time_in_words(actual_tote_items_gap)      
      assert actual_tote_item_postings_gap > 7.days
    elsif posting_frequency == 5
      expected_tote_items_gap_lo = (28 * subscription_frequency).days
      expected_tote_items_gap_hi = (37 * subscription_frequency).days

      assert actual_tote_items_gap >= expected_tote_items_gap_lo
      assert actual_tote_items_gap <= expected_tote_items_gap_hi
    else
      assert false, "incorrect posting_frequency"
    end

  end

  test "frequency permutation 1 and 1" do    
    if @on
      do_frequencies_permutation(1, 1)
    end
  end

  test "frequency permutation 1 and 2" do
    if @on
      do_frequencies_permutation(1, 2)
    end    
  end

  test "frequency permutation 1 and 3" do    
    if @on
      do_frequencies_permutation(1, 3)
    end    
  end

  test "frequency permutation 1 and 4" do
    if @on
      do_frequencies_permutation(1, 4)
    end    
  end

  test "frequency permutation 2 and 1" do    
    if @on
      do_frequencies_permutation(2, 1)
    end    
  end

  test "frequency permutation 2 and 2" do
    if @on
      do_frequencies_permutation(2, 2)
    end    
  end

  test "frequency permutation 2 and 3" do    
    if @on
      do_frequencies_permutation(2, 3)
    end    
  end

  test "frequency permutation 2 and 4" do
    if @on
      do_frequencies_permutation(2, 4)
    end    
  end

  test "frequency permutation 3 and 1" do    
    if @on
      do_frequencies_permutation(3, 1)
    end    
  end

  test "frequency permutation 3 and 2" do
    if @on
      do_frequencies_permutation(3, 2)
    end    
  end

  test "frequency permutation 4 and 1" do    
    if @on
      do_frequencies_permutation(4, 1)
    end    
  end

  test "frequency permutation 4 and 2" do
    if @on
      do_frequencies_permutation(4, 2)
    end    
  end

  def do_frequencies_permutation(posting_frequency, subscription_frequency)

    product = products(:apples)
    posting = setup_posting_recurrence(product, posting_frequency)

    user = users(:c1)    
    quantity = 2    

    posting_recurrence = posting.posting_recurrence
    travel_to posting_recurrence.postings.last.order_cutoff - 1.hour

    num_tote_items_start = user.tote_items.count    
    num_tote_items_end = user.tote_items.count + 4

    while user.tote_items.count < num_tote_items_end

      puts Time.zone.now.strftime("%A, %B %d, %H")
      puts "Number of tote items: #{user.tote_items.count.to_s}"

      top_of_hour = Time.zone.now.min == 0

      if top_of_hour
        RakeHelper.do_hourly_tasks        
      end

      posting_recurrence.reload

      if posting_recurrence.postings.count >= 2 && user.tote_items.count == num_tote_items_start
        add_subscription(user, posting_recurrence.postings.last, quantity, subscription_frequency)      
      end                

      #if you draw out a postings series you'll see that the last inthe series is always open because the moment time enters the 
      #commitment zone of the last we generate the next posting, which becomes the 'last', which is OPEN

      last_posting = posting_recurrence.postings.last
      assert last_posting.state?(:OPEN)
      assert last_posting.live

      #if you draw out a postings series you'll see that if there are more than 1 postings in the series, the second to last
      #is either in its commitment zone or closed. and all the other postings will be closed
      second_last = posting_recurrence.postings.order(id: :desc).second

      if second_last != nil

        #get number of CLOSED postings
        num_closed_postings = posting_recurrence.postings.where(state: Posting.states[:CLOSED]).count
        
        if Time.zone.now < second_last.delivery_date
          if second_last.total_quantity_authorized_or_committed == 0
            assert second_last.state?(:CLOSED)
            #assert num CLOSED postings is postings.count - 2
            assert_equal posting_recurrence.postings.count - 1, num_closed_postings
          else
            assert second_last.state?(:COMMITMENTZONE)
            #assert num CLOSED postings is postings.count - 2
            assert_equal posting_recurrence.postings.count - 2, num_closed_postings          
          end          

        elsif Time.zone.now > second_last.delivery_date + 12.hours

          if !second_last.state?(:CLOSED)
            fill_posting(second_last, 1000)
            #refresh
            num_closed_postings = posting_recurrence.postings.where(state: Posting.states[:CLOSED]).count
          end

          assert second_last.state?(:CLOSED)
          #assert num CLOSED postings is postings.count - 1
          assert_equal posting_recurrence.postings.count - 1, num_closed_postings
        end

        assert_not second_last.live

      end

      travel 60.minutes

    end

    travel_back

    do_posting_spacing(posting_recurrence)
    do_tote_item_spacing(posting_recurrence)    

  end

  #to add new product/posting to this farmer create a producer_product_commission

  test "subscriptions" do

    if !@on
      next
    end

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

    num_c17_deliveries = posting_recurrences.first.postings.where(state: Posting.states[:CLOSED]).count
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
    #TODO tests:
    #verify a subscription was added
    #verify subscription points to postingrecurrence
    #verify postingrecurrence points to posting
    #verify tote item points to subscription

    log_in_as(user)
    post user_dropsites_path, params: {user_dropsite: {dropsite_id: dropsites(:dropsite1).id}}
    post tote_items_path, params: {tote_item: {quantity: quantity, posting_id: posting.id}}
    tote_item = assigns(:tote_item)
    post subscriptions_path, params: {tote_item_id: tote_item.id, frequency: frequency}

    subscription = assigns(:subscription)
    assert_not subscription.nil?

    get tote_items_path
    assert :success
    assert_template 'tote_items/tote'
    items_total_gross = assigns(:items_total_gross)

    if items_total_gross > 0
      post checkouts_path, params: {use_reference_transaction: 1}
      checkout = assigns(:checkout)
      post rtauthorizations_create_path, params: {token: checkout.token}
    end

    #TODO: tests
    #verify ba points to user
    #verify rtauth points to ba
    #verify rtauth points to subscription
    #verify rtauth points to toteitem
    #verify authorization receipt sent out

    return subscription

  end

  def setup_posting_recurrence(product, frequency)

    farmer = users(:f_subscriptions)
    log_in_as(farmer)

    unit = units(:pound)

    if ProducerProductUnitCommission.where(user: farmer, product: product, unit: unit).count < 1      
      ppuc = ProducerProductUnitCommission.create(user: farmer, product: product, unit: unit, commission: 0.05)
    end
    
    delivery_date = next_day_of_week_after(Time.zone.now, 5, 7)
    post postings_path, params: {posting: {
      description: "#{product.name} description",
      price: 2,
      user_id: farmer.id,
      product_id: product.id,
      unit_id: unit.id,
      live: true,
      delivery_date: delivery_date,
      order_cutoff: delivery_date - 2.days,
      posting_recurrence: {frequency: frequency, on: true}
    }}

    posting = assigns(:posting)

    return posting

  end

  def setup_posting_recurrences

    postings = []

    frequency = 1
    
    postings << setup_posting_recurrence(products(:apples), frequency)
    assert postings.last.valid?
    postings << setup_posting_recurrence(products(:lettuce), frequency)
    assert postings.last.valid?
    postings << setup_posting_recurrence(products(:tomato), frequency)   
    assert postings.last.valid?

    return postings

  end

  def get_nearest_posting(posting_recurrences)

    nearest_posting = posting_recurrences.first.postings.first

    posting_recurrences.each do |pr|
      pr.reload
      pr.postings.each do |posting|          
        posting.reload
        if posting.delivery_date < nearest_posting.delivery_date
          nearest_posting = posting          
        end
      end        
    end    

    return nearest_posting

  end

  def time_loop(posting_recurrences, num_days)

    current_time = get_nearest_posting(posting_recurrences).order_cutoff - 1.hour
    end_minute = current_time + num_days.days

    travel_to current_time
    num_loops = 0

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
                fill_posting(posting)
              end              
            end
          end        
        end
      end

      travel 60.minutes
      current_time = Time.zone.now

      num_loops += 1

      if num_loops % 24 == 0                
        puts Time.zone.now.strftime("%A, %B %d, %H")
      end
            
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
