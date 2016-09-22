require 'test_helper'
require 'utility/rake_helper'

class SubscriptionsTest < ActionDispatch::IntegrationTest
  
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
    producer = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "PRODUCER 1 FARMS")        
    jan6 = Time.zone.local(2016, 1, 6)
    delivery_date = jan6
    commitment_zone_start = delivery_date - 2.days

    #jump to first commitment zone in the series
    travel_to commitment_zone_start
    #Monday Jan 4
    posting = create_posting(producer, 2.50, product = nil, unit = nil, delivery_date, commitment_zone_start, commission = 0.05)
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
    jane = create_user("jane", "jane@j.com", 98033)
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
      travel_to posting_recurrence.reload.current_posting.commitment_zone_start
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
    travel_to posting_recurrence.reload.current_posting.commitment_zone_start
    #Mon Feb 15
    assert_equal Time.zone.local(2016,2,15), posting_recurrence.reload.current_posting.commitment_zone_start
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
    producer = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "PRODUCER 1 FARMS")        
    jan6 = Time.zone.local(2016, 1, 6)
    delivery_date = jan6
    commitment_zone_start = delivery_date - 2.days

    #jump to first commitment zone in the series
    travel_to commitment_zone_start
    #Monday Jan 4
    posting = create_posting(producer, 2.50, product = nil, unit = nil, delivery_date, commitment_zone_start, commission = 0.05)
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
    jane = create_user("jane", "jane@j.com", 98033)
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




    travel_to posting_recurrence.reload.current_posting.commitment_zone_start
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
    assert_equal 2, skip_dates.count

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
    do_delivery(posting)
    #verify INDD got filled
    assert indd.reload.state?(:FILLED)
    assert indd.fully_filled?

    #verify next not skipped
    posting = do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    do_delivery(posting)
    #next should be FILLED    
    assert next_ti.reload.state?(:FILLED)

    #first and second FILLED ti's should match the 2 skip dates given earlier
    assert_equal indd.posting.delivery_date, skip_dates[0][:date]
    assert_equal next_ti.posting.delivery_date, skip_dates[1][:date]

    #first and second ti's should not be the same object
    assert_not indd == next_ti
    #first and second ti's should be separated by 7 days
    assert_equal 7.days, next_ti.posting.delivery_date - indd.posting.delivery_date

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
    assert_equal 2, skip_dates.count

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

    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    do_delivery(indd.posting)

    #we should now be on the delivery day of the INDD
    assert_equal Time.zone.now.midnight, indd.posting.delivery_date
    #the 'next' ti should have been generated for the subscription
    assert_equal 2, subscription.reload.tote_items.count
    #this 'next' ti should be out ahead of INDD
    assert subscription.tote_items.last.posting.delivery_date > indd.posting.delivery_date
    #assert INDD really is REMOVED
    assert indd.reload.state?(:REMOVED)

    #verify 'next' gets filled
    posting = subscription.reload.posting_recurrence.current_posting
    do_current_posting_order_cutoff_tasks(subscription.posting_recurrence)
    do_delivery(posting)

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
    travel_to tote_item.posting.commitment_zone_start    
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
        post subscriptions_skip_dates_path, params: {skip_dates: {subscription.id.to_s => [skip_dates.second[:date].to_s]}, subscription_ids: [subscription.id.to_s], end_date: (skip_dates.second[:date] + 7.days).to_s}
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
    travel_to tote_item.posting.commitment_zone_start

    num_tote_items = user.tote_items.count
    pause_time = Time.zone.now - 1.year
    regular_tote_item_delivery_gap = 1.minute
    has_paused = false

    30.times do

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

      travel 1.day

    end

    travel_back

    user.reload
    assert_equal user.tote_items.count, num_tote_items + subscription.tote_items.count - 1
    assert_equal subscription.tote_items.count, apples_posting.posting_recurrence.postings.count
    gap = subscription.tote_items[1].posting.delivery_date - subscription.tote_items[0].posting.delivery_date
    assert_equal 7.days, gap    

    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[0].state
    assert_equal ToteItem.states[:REMOVED], subscription.tote_items[1].state
    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[2].state
    gap = subscription.tote_items[2].posting.delivery_date - subscription.tote_items[0].posting.delivery_date    
    assert_equal 14.days, gap
    
    gap = subscription.tote_items[3].posting.delivery_date - subscription.tote_items[2].posting.delivery_date
    assert_equal 7.days, gap

  end

  test "should not generate tote items after subscription is turned off" do

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
    travel_to tote_item.posting.commitment_zone_start

    num_tote_items = user.tote_items.count
    pause_time = Time.zone.now - 1.year
    regular_tote_item_delivery_gap = 1.minute
    has_paused = false

    30.times do

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

    user.reload
    assert_equal num_tote_items + 1, user.tote_items.count

    #as of this writing only two items should have been generated in this series. they should be without gap (i.e. 7 day spacing)
    #right at the beginning of the posting recurrence series. then the turn_off method gets called so their shoudl be no further
    #tote items. but the pr should keep chugging so there should be a big gap between the last posting in the pr series vs the ti series
    gap = subscription.tote_items[1].posting.delivery_date - subscription.tote_items[0].posting.delivery_date
    assert_equal 7.days, gap
    apples_posting.reload
    gap = apples_posting.posting_recurrence.postings.last.delivery_date - subscription.tote_items.last.posting.delivery_date
    assert gap > 7.days

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
    travel_to posting_recurrence.postings.last.commitment_zone_start - 1.hour

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
            second_last.fill(1000)
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

  def do_posting_spacing(posting_recurrence)

    postings = posting_recurrence.postings
    assert postings.count > 1, "there aren't enough postings in this recurrence to test the spacing"

    seconds_per_hour = 60 * 60
    num_seconds_per_week = 7 * 24 * seconds_per_hour

    if posting_recurrence.frequency <= 4      

      count = 1
      while count < postings.count

        spacing = postings[count].delivery_date - postings[count - 1].delivery_date

        if !postings[count].delivery_date.dst? && postings[count - 1].delivery_date.dst?
          spacing -= seconds_per_hour
        end

        if postings[count].delivery_date.dst? && !postings[count - 1].delivery_date.dst?
          spacing += seconds_per_hour
        end        

        assert_equal num_seconds_per_week * posting_recurrence.frequency, spacing
        count += 1

      end

    elsif posting_recurrence.frequency == 5
      assert false, "do_posting_spacing doesn't test frequency 5 yet"      
    end

  end

  def do_tote_item_spacing(posting_recurrence)

    seconds_per_hour = 60 * 60
    num_seconds_per_week = 7 * 24 * seconds_per_hour
    postings = posting_recurrence.postings
    subscription = posting_recurrence.subscriptions.last
    tote_items = subscription.tote_items

    assert postings.count > 1, "there aren't enough postings in this recurrence to test the tote items spacing"
    assert tote_items.count > 1, "there aren't enough tote_items in this subscription to test the tote items spacing"

    if posting_recurrence.frequency <= 4

      count = 1
      while count < tote_items.count

        actual_spacing = tote_items[count].posting.delivery_date - tote_items[count - 1].posting.delivery_date
        expected_spacing = num_seconds_per_week * posting_recurrence.frequency * subscription.frequency

        if !tote_items[count].posting.delivery_date.dst? && tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing += seconds_per_hour
        end

        if tote_items[count].posting.delivery_date.dst? && !tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing -= seconds_per_hour
        end

        assert_equal expected_spacing, actual_spacing
        count += 1
      end

    elsif posting_recurrence.frequency == 5
      assert false, "do_tote_item_spacing doesn't test frequency 5 yet"
    end

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
    assert_template 'tote_items/index'
    total_amount_to_authorize = assigns(:total_amount_to_authorize)

    if total_amount_to_authorize > 0
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
      quantity_available: 100,
      price: 2,
      user_id: farmer.id,
      product_id: product.id,
      unit_id: unit.id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days,
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

    current_time = get_nearest_posting(posting_recurrences).commitment_zone_start - 1.hour
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
                log_in_as(users(:a1))
                post postings_fill_path, params: {posting_id: posting.id, quantity: posting.total_quantity_authorized_or_committed}
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
