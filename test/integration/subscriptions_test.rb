require 'test_helper'

class SubscriptionsTest < ActionDispatch::IntegrationTest
  
  def setup
    @on = false
  end  

  #i'm wanting to make a general test framework where i can crank out the implementations for 
  #posting recurrence and subscription frequency permutations
  #puts Time.zone.now.strftime("%A, %B %d, %H")
  #error loading meta info from Packages/Default/Icon (Source).tmPreferences: Unable to open Packages/Default/Icon (Source).tmPreferences

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
          assert second_last.state?(:COMMITMENTZONE)
          #assert num CLOSED postings is postings.count - 2
          assert_equal posting_recurrence.postings.count - 2, num_closed_postings          
        elsif Time.zone.now > second_last.delivery_date + 12.hours
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

    num_seconds_per_week = 7 * 24 * 60 * 60    

    if posting_recurrence.frequency <= 4      

      i = 1
      while i < postings.count
        spacing = postings[i].delivery_date - postings[i - 1].delivery_date
        assert_equal num_seconds_per_week * posting_recurrence.frequency, spacing
        i += 1
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

    num_seconds_per_week = 7 * 24 * 60 * 60
    postings = posting_recurrence.postings
    subscription = posting_recurrence.subscriptions.last
    tote_items = subscription.tote_items

    assert postings.count > 1, "there aren't enough postings in this recurrence to test the tote items spacing"
    assert tote_items.count > 1, "there aren't enough tote_items in this subscription to test the tote items spacing"

    if posting_recurrence.frequency <= 4

      i = 1
      while i < tote_items.count
        spacing = tote_items[i].posting.delivery_date - tote_items[i - 1].posting.delivery_date
        assert_equal num_seconds_per_week * posting_recurrence.frequency * subscription.frequency, spacing
        i += 1
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

    post tote_items_path, tote_item: {
      quantity: quantity,      
      posting_id: posting.id,
      subscription_frequency: frequency
    }

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
