require 'test_helper'

class SubscriptionsTest < ActionDispatch::IntegrationTest
  
  def setup
    @on = false
    @farmer = users(:f1)
    @product = products(:apples)
    @unit_category = unit_categories(:weight)
    @unit_kind = unit_kinds(:pound)    
    @posting = postings(:postingf1apples)
  end  

  test "skip dates should be spaced 2 weeks apart for a 6 and 2 subscription" do

    user = users(:c1)
    pr = posting_recurrences(:three)

    travel_to pr.postings.first.commitment_zone_start - 24.hours
    time_of_this_writing = Time.zone.local(2016, 6, 1, 12, 0)

    while Time.zone.now < (time_of_this_writing - 1.day)
      RakeHelper.do_hourly_tasks
      travel 24.hours
    end

    log_in_as(user)
    add_subscription(user, pr.postings.last, quantity = 1, frequency = 2)
    user.reload
    subscription = user.subscriptions.last
    
    get edit_subscription_path(id: subscription.id, end_date: pr.postings.first.delivery_date + 20.weeks)
    skip_dates = assigns(:skip_dates)

    #should be 2 week gap between first tote item and first skip date
    ti_dd = subscription.tote_items.last.delivery_date
    sd = skip_dates[0][:date]
    gap = sd - ti_dd
    assert_equal 2.weeks, gap

    #should be 2 week gap between all the skip dates    
    count = 1
    while count < skip_dates.count
      gap = skip_dates[count][:date] - skip_dates[count - 1][:date]
      assert_equal 2.weeks, gap
      count += 1
    end

    travel_back

  end

  #i'm wanting to make a general test framework where i can crank out the implementations for 
  #posting recurrence and subscription frequency permutations
  #puts Time.zone.now.strftime("%A, %B %d, %H")
  #error loading meta info from Packages/Default/Icon (Source).tmPreferences: Unable to open Packages/Default/Icon (Source).tmPreferences

  test "should neither show frequency 2 as option nor allow subscription creation with frequency 2 during martys week number 2" do
    #log in as farmer    
    log_in_as(@farmer)
    #create posting with posting recurrence frequency of 6

    delivery_date = Time.zone.today.midnight + 14.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end
    commitment_zone_start = delivery_date - 2.days
    posting_recurrence_count = PostingRecurrence.joins(postings: :user).where("users.id = ?", @farmer.id).count

    post postings_path, posting: {
      description: "my recurring posting",
      quantity_available: 100,
      price: 2,
      user_id: @farmer.id,
      product_id: @product.id,
      unit_category_id: @unit_category.id,
      unit_kind_id: @unit_kind.id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: commitment_zone_start,
      posting_recurrence: {frequency: 6, on: true}
    }

    posting = assigns(:posting)
    posting_recurrence = posting.posting_recurrence
    assert_not posting.nil?
    assert posting.id > 0
    assert_equal posting_recurrence_count + 1, PostingRecurrence.joins(postings: :user).where("users.id = ?", @farmer.id).count
    assert_equal 1, posting_recurrence.postings.count

    #wind the clock to just prior to the commitment zone
    travel_to posting.commitment_zone_start - 1.hour
    #verify the shopping pages can be loaded
    c1 = users(:c1)
    log_in_as(c1)
    get postings_path
    #verify the shopping tote can be loaded
    get tote_items_path

    #now have c2 add a bi-weekly subscription
    c2 = users(:c2)
    c2_subscription_count = c2.subscriptions.count
    c2_tote_items_count = c2.tote_items.count
    
    add_subscription(c2, posting, quantity = 1, frequency = 2)    
    
    c2.reload
    assert_equal c2_tote_items_count + 1, c2.tote_items.count
    assert_equal c2_subscription_count + 1, c2.subscriptions.count

    #wind clock forward into first posting's cz. this will put us smack in the middle of "week #2", which is a no-no for
    #subscription frequency #2 (i.e. every other week)
    travel_to posting.commitment_zone_start
    RakeHelper.do_hourly_tasks
    travel 1.hour

    #the whole purpose of c2 is to verify that he can see the description for his subscription even during week 2. so this test is multi-purpose:
    #to verify that c1 cannot ADD a subscription during week 2 but also to ensure that users with existing bi-weekly sx can still see a description
    #verify c2 can load shopping pages and tote
    get postings_path    
    get tote_items_path
    tote_items = assigns(:tote_items)
    assert_match "This is a subscription for 1 Pound of F1 FARM Fuji Apples delivered every other week for a subtotal of $2.00 each delivery", response.body

    #have user create a new tote item
    posting_recurrence.reload
    log_in_as(c1)    
    subscriptions_count = c1.subscriptions.count    
    post tote_items_path, tote_item: {quantity: 1, posting_id: posting_recurrence.postings.last.id}
    tote_item = assigns(:tote_item)
    assert_redirected_to new_subscription_path(tote_item_id: tote_item.id)
    follow_redirect!
    #verify every-other-week option is not available
    subscription_create_options = assigns(:subscription_create_options)
    subscription_create_options.each do |subscription_create_option|
      assert_not_equal 2, subscription_create_option[:subscription_frequency]
    end
    #despite every-other-week option not being available, attempt to create every-other-week frequency subscription
    post subscriptions_path, tote_item_id: tote_item.id, frequency: 2
    #verify subscription creation attempt failed
    c1.reload
    assert_equal subscriptions_count, c1.subscriptions.count

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
        post subscriptions_skip_dates_path, skip_dates: {subscription.id.to_s => [skip_dates.first[:date].to_s]}, subscription_ids: [subscription.id.to_s], end_date: (skip_dates.first[:date] + 1.week).to_s
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
        patch subscription_path(subscription), subscription: { paused: "1", on: "1" }
        subscription.reload
        assert subscription.paused
        pause_time = Time.zone.now
        regular_tote_item_delivery_gap = subscription.tote_items.last.posting.delivery_date - subscription.tote_items.first.posting.delivery_date
        has_paused = true
      end

      #unpause subscription one delivery cycle after pausing it
      if subscription.paused && (Time.zone.now == (pause_time + regular_tote_item_delivery_gap))
        patch subscription_path(subscription), subscription: { paused: "0", on: "1" }
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
    assert_equal 1.week, gap    

    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[0].state
    assert_equal ToteItem.states[:REMOVED], subscription.tote_items[1].state
    assert_equal ToteItem.states[:COMMITTED], subscription.tote_items[2].state
    gap = subscription.tote_items[2].posting.delivery_date - subscription.tote_items[0].posting.delivery_date    
    assert_equal 2.weeks, gap
    
    gap = subscription.tote_items[3].posting.delivery_date - subscription.tote_items[2].posting.delivery_date
    assert_equal 1.week, gap

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
        patch subscription_path(subscription), subscription: { paused: "0", on: "0" }
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
    assert_equal 1.week, gap
    apples_posting.reload
    gap = apples_posting.posting_recurrence.postings.last.delivery_date - subscription.tote_items.last.posting.delivery_date
    assert gap > 1.week    

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

  #posting: 3 on, 1 off. subscription: every delivery
  test "frequency permutation 6 and 1" do
    if @on
      do_frequencies_permutation(6, 1)
    end    
  end

  #posting: 3 on, 1 off. subscription: every other week
  test "frequency permutation 6 and 2" do
    if @on
      do_frequencies_permutation(6, 2)
    end
  end

  #posting: 3 on, 1 off. subscription: every 4 weeks
  test "frequency permutation 6 and 3" do
    if @on
      do_frequencies_permutation(6, 3)
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

      if posting_frequency == 6 && subscription_frequency == 2
        #scabbed this garbage in because 6/2 can't add sx on week number 2 of marty's cycle so have to wiat until the next posting comes out
        if posting_recurrence.postings.count >= 3 && user.tote_items.count == num_tote_items_start
          add_subscription(user, posting_recurrence.postings.last, quantity, subscription_frequency)      
        end      
      else
        if posting_recurrence.postings.count >= 2 && user.tote_items.count == num_tote_items_start
          add_subscription(user, posting_recurrence.postings.last, quantity, subscription_frequency)      
        end                
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
          assert second_last.state?(:COMMITMENTZONE)
          #assert num CLOSED postings is postings.count - 2
          assert_equal posting_recurrence.postings.count - 2, num_closed_postings          
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
    elsif posting_recurrence.frequency == 6

      i = 1
      while i < postings.count
        if i % 3 == 0
          #there should be a two week gap
          expected_gap = 2.weeks
        else
          #there should be a 1 week gap
          expected_gap = 1.week
        end
        actual_gap = postings[i].delivery_date - postings[i - 1].delivery_date
        assert_equal expected_gap, actual_gap
        i += 1
      end
      
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
    elsif posting_recurrence.frequency == 6
      case subscription.frequency
      when 1 #every delivery

        if tote_items.count > 3
          #we should have at least one 2 week gap
          i = 1
          num_2_week_gaps = 0
          while i < tote_items.count            
            gap = tote_items[i].posting.delivery_date - tote_items[i - 1].posting.delivery_date            
            if gap > 1.week
              num_2_week_gaps += 1
            end
            i += 1
          end

          assert num_2_week_gaps > 0, "num_2_week_gaps should be > 0. It's not. It's #{num_2_week_gaps.to_s}."

        end
      
      when 2 #every other week

        i = 1
        while i < tote_items.count
          gap = tote_items[i].posting.delivery_date - tote_items[i - 1].posting.delivery_date
          assert_equal num_seconds_per_week * 2, gap
          i += 1
        end        

      when 3 #every 4 weeks

        i = 1
        while i < tote_items.count
          gap = tote_items[i].posting.delivery_date - tote_items[i - 1].posting.delivery_date
          assert_equal num_seconds_per_week * 4, gap
          i += 1
        end

      end
      
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
    post user_dropsites_path, user_dropsite: {dropsite_id: dropsites(:dropsite1).id}
    post tote_items_path, tote_item: {quantity: quantity, posting_id: posting.id}
    tote_item = assigns(:tote_item)
    post subscriptions_path, tote_item_id: tote_item.id, frequency: frequency

    subscription = assigns(:subscription)

    if frequency == 2 && posting.posting_recurrence.frequency == 6 && !posting.posting_recurrence.can_add_tote_item?(frequency)
      assert subscription.nil?
    else
      assert_not subscription.nil?
    end    

    get tote_items_path
    assert :success
    assert_template 'tote_items/index'
    total_amount_to_authorize = assigns(:total_amount_to_authorize)

    if total_amount_to_authorize > 0
      post checkouts_path, use_reference_transaction: 1
      checkout = assigns(:checkout)
      post rtauthorizations_create_path, token: checkout.token
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
    
    delivery_date = next_day_of_week_after(Time.zone.now, 5, 7)
    post postings_path, posting: {
      description: "#{product.name} description",
      quantity_available: 100,
      price: 2,
      user_id: farmer.id,
      product_id: product.id,
      unit_category_id: unit_categories(:weight).id,
      unit_kind_id: unit_kinds(:pound).id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days,
      posting_recurrence: {frequency: frequency, on: true}
    }

    posting = assigns(:posting)

    return posting

  end

  def setup_posting_recurrences

    postings = []

    frequency = 1
    
    postings << setup_posting_recurrence(products(:apples), frequency)
    postings << setup_posting_recurrence(products(:lettuce), frequency)
    postings << setup_posting_recurrence(products(:tomato), frequency)

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
                post postings_fill_path, posting_id: posting.id, quantity: posting.total_quantity_authorized_or_committed
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
