require 'test_helper'
require 'utility/rake_helper'

class PostingRecurrenceTest < ActiveSupport::TestCase
  
  def setup
  	
    @posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    @posting_recurrence.postings << postings(:postingf1apples)
    @posting_recurrence.save
    @posting_recurrence.recur

    @subscription = @posting_recurrence.subscriptions.create(frequency: 1, on: true, quantity: 1)        
    @subscription.user = users(:c1)
    @subscription.save
    @subscription.generate_next_tote_item    

  end

  test "delivery wday should change from wednesday to thursday" do

    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting_recurrence.postings << postings(:posting_subscription_farmer)
    posting_recurrence.save
    assert_equal 1, posting_recurrence.postings.count

    #change to a static delivery date to make computation stuff easier
    #this is a wednesday
    posting_recurrence.postings.first.update(order_cutoff: Time.zone.local(2016,9,5))
    posting_recurrence.postings.first.update(delivery_date: Time.zone.local(2016,9,7))
    #verify first posting is on wednesday
    assert_equal 3, posting_recurrence.reload.postings.first.delivery_date.wday

    #change to posting 1's order cutoff and generate next posting
    travel_to posting_recurrence.postings.first.order_cutoff
    RakeHelper.do_hourly_tasks
    #verify another posting was created
    assert_equal 2, posting_recurrence.postings.count
    #verify second posting is on wednesday
    assert_equal 3, posting_recurrence.reload.postings.last.delivery_date.wday

    #change delivery day to thursday
    assert posting_recurrence.change_delivery_day?(4)
    #verify second posting is on thursday
    assert_equal 4, posting_recurrence.reload.postings.last.delivery_date.wday
    assert_equal Time.zone.local(2016,9,15), posting_recurrence.reload.postings.last.delivery_date

    #travel to last posting's order cutoff, generate new posting and verify the new posting is on a thursday
    travel_to posting_recurrence.postings.last.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 3, posting_recurrence.postings.count
    assert_equal 4, posting_recurrence.reload.postings.last.delivery_date.wday
    assert_equal Time.zone.local(2016,9,22), posting_recurrence.reload.postings.last.delivery_date

    travel_back

  end

  test "delivery wday should change from thursday to wednesday" do

    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting_recurrence.postings << postings(:posting_subscription_farmer)
    posting_recurrence.save
    assert_equal 1, posting_recurrence.postings.count

    #change to a static delivery date to make computation stuff easier
    #this is a thursday
    posting_recurrence.postings.first.update(order_cutoff: Time.zone.local(2016,9,6))
    posting_recurrence.postings.first.update(delivery_date: Time.zone.local(2016,9,8))
    #verify first posting is on thursday
    assert_equal 4, posting_recurrence.reload.postings.first.delivery_date.wday

    #change to posting 1's order cutoff and generate next posting
    travel_to posting_recurrence.postings.first.order_cutoff
    RakeHelper.do_hourly_tasks
    #verify another posting was created
    assert_equal 2, posting_recurrence.postings.count
    #verify second posting is on thursday
    assert_equal 4, posting_recurrence.reload.postings.last.delivery_date.wday

    #change delivery day to wednesday
    assert posting_recurrence.change_delivery_day?(3)
    #verify second posting is on wednesday
    assert_equal 3, posting_recurrence.reload.postings.last.delivery_date.wday
    assert_equal Time.zone.local(2016,9,14), posting_recurrence.reload.postings.last.delivery_date

    #travel to last posting's order cutoff, generate new posting and verify the new posting is on a wednesday
    travel_to posting_recurrence.postings.last.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 3, posting_recurrence.postings.count
    assert_equal 3, posting_recurrence.reload.postings.last.delivery_date.wday
    assert_equal Time.zone.local(2016,9,21), posting_recurrence.reload.postings.last.delivery_date

    travel_back

  end

  test "should recur even with no orders" do

    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting_recurrence.postings << postings(:posting_subscription_farmer)
    posting_recurrence.save
    assert_equal 1, posting_recurrence.postings.count

    travel_to posting_recurrence.postings.last.order_cutoff + 1
    posting_recurrence.postings.last.transition(:order_cutoffed)
    assert_equal 2, posting_recurrence.postings.count

    assert_equal 0, posting_recurrence.postings.first.tote_items.count
    assert_equal 0, posting_recurrence.postings.last.tote_items.count

    travel_back

  end

  test "should turn off" do

    #this should not only turn off the recurrence itself but also ripple through to turn off
    #all subscriptions based off it

    assert @posting_recurrence.on

    assert @posting_recurrence.on
    assert_equal 1, @posting_recurrence.subscriptions.count
    assert @posting_recurrence.subscriptions.first.on

    @posting_recurrence.turn_off    
    assert_not @posting_recurrence.on
    assert_not @posting_recurrence.on    
    assert_not @posting_recurrence.subscriptions.first.on

    pr = @posting_recurrence.reload
    s = @posting_recurrence.subscriptions.first.reload

    assert_not pr.on
    assert_not pr.on
    assert_not s.on

  end

  test "should be subscribable" do
    assert @posting_recurrence.on
  end

  test "should have legit subscription options" do
    monthly_posting_recurrence = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 5, order_minimum_producer_net = 0).posting_recurrence
    monthly_options = monthly_posting_recurrence.subscription_create_options

    options = @posting_recurrence.subscription_create_options

    assert_not options.nil?
    assert_equal "Just once", options[0][:text]
    assert_equal "Every week", options[1][:text]
    assert_equal "Every 2 weeks", options[2][:text]
    assert_equal "Every 3 weeks", options[3][:text]
    assert_equal "Every 4 weeks", options[4][:text]

    assert_equal "Just once", monthly_options[0][:text]
    assert_match "every month", monthly_options[1][:text]
    assert_match "every 2nd month", monthly_options[2][:text]

    assert_equal 0, options[0][:subscription_frequency]
    assert_equal 1, options[1][:subscription_frequency]
    assert_equal 2, options[2][:subscription_frequency]
    assert_equal 3, options[3][:subscription_frequency]
    assert_equal 4, options[4][:subscription_frequency]

    assert_equal 0, monthly_options[0][:subscription_frequency]
    assert_equal 1, monthly_options[1][:subscription_frequency]
    assert_equal 2, monthly_options[2][:subscription_frequency]

    delivery_date = @posting_recurrence.postings.last.delivery_date

    assert_equal delivery_date, options[0][:next_delivery_date]
    assert_equal delivery_date, options[1][:next_delivery_date]
    assert_equal delivery_date, options[2][:next_delivery_date]
    assert_equal delivery_date, options[3][:next_delivery_date]
    assert_equal delivery_date, options[4][:next_delivery_date]

    delivery_date = monthly_posting_recurrence.postings.last.delivery_date
    assert_equal delivery_date, monthly_options[0][:next_delivery_date]
    assert_equal delivery_date, monthly_options[1][:next_delivery_date]
    assert_equal delivery_date, monthly_options[2][:next_delivery_date]

  end

  test "should not be subscribable" do
    @posting_recurrence.turn_off
    assert_not @posting_recurrence.on
    @posting_recurrence.reload
  end

  test "verify get delivery dates method 1" do
    
    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)
    posting = postings(:postingf1apples)
    mar29 = Time.zone.local(2016,3,29)    
    posting.delivery_date = mar29
    posting.order_cutoff = mar29 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + (8 * 7).days)

    assert_equal 8, delivery_dates.count
    
    assert_equal Time.zone.local(2016,4,5), delivery_dates[0]
    assert_equal Time.zone.local(2016,4,12), delivery_dates[1]
    assert_equal Time.zone.local(2016,4,19), delivery_dates[2]
    assert_equal Time.zone.local(2016,4,26), delivery_dates[3]
    assert_equal Time.zone.local(2016,5,3), delivery_dates[4]
    assert_equal Time.zone.local(2016,5,10), delivery_dates[5]
    assert_equal Time.zone.local(2016,5,17), delivery_dates[6]
    assert_equal Time.zone.local(2016,5,24), delivery_dates[7]

  end

  test "verify get delivery dates method 1 for monthly recurrence" do
    
    posting_recurrence_frequency = 5

    order_cutoff = Time.zone.local(2016, 8, 29, 8)
    delivery_date = Time.zone.local(2016, 9, 2)

    #you have to travel to prior to order cutoff cause otherwise the posting will not .save properly
    travel_to order_cutoff - 1.day

    monthly_posting_recurrence = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date, order_cutoff, units_per_case = nil, posting_recurrence_frequency, order_minimum_producer_net = 0).posting_recurrence

    delivery_dates = monthly_posting_recurrence.get_delivery_dates_for(delivery_date, delivery_date + (8 * 31).days)
    assert_equal 8, delivery_dates.count
    
    assert_equal Time.zone.local(2016,10,7), delivery_dates[0]
    assert_equal Time.zone.local(2016,11,4), delivery_dates[1]
    assert_equal Time.zone.local(2016,12,2), delivery_dates[2]
    assert_equal Time.zone.local(2017,1,6), delivery_dates[3]
    assert_equal Time.zone.local(2017,2,3), delivery_dates[4]
    assert_equal Time.zone.local(2017,3,3), delivery_dates[5]
    assert_equal Time.zone.local(2017,4,7), delivery_dates[6]
    assert_equal Time.zone.local(2017,5,5), delivery_dates[7]

    travel_back

  end

  test "verify get delivery dates method 2" do

    posting_recurrence = PostingRecurrence.new(frequency: 2, on: true)
    posting = postings(:postingf1apples)
    mar29 = Time.zone.local(2016,3,29)    
    posting.delivery_date = mar29
    posting.order_cutoff = mar29 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + (8 * 7).days)

    assert_equal 4, delivery_dates.count
        
    assert_equal Time.zone.local(2016,4,12), delivery_dates[0]
    assert_equal Time.zone.local(2016,4,26), delivery_dates[1]    
    assert_equal Time.zone.local(2016,5,10), delivery_dates[2]
    assert_equal Time.zone.local(2016,5,24), delivery_dates[3]

  end

  test "verify get delivery dates method 3" do

    posting_recurrence = PostingRecurrence.new(frequency: 3, on: true)
    posting = postings(:postingf1apples)
    mar29 = Time.zone.local(2016,3,29)    
    posting.delivery_date = mar29
    posting.order_cutoff = mar29 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + (8 * 7).days)

    assert_equal 2, delivery_dates.count
        
    assert_equal Time.zone.local(2016,4,19), delivery_dates[0]
    assert_equal Time.zone.local(2016,5,10), delivery_dates[1]

  end

  test "verify get delivery dates method 4" do

    posting_recurrence = PostingRecurrence.new(frequency: 4, on: true)
    posting = postings(:postingf1apples)
    mar29 = Time.zone.local(2016,3,29)    
    posting.delivery_date = mar29
    posting.order_cutoff = mar29 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + (8 * 7).days)

    assert_equal 2, delivery_dates.count
        
    assert_equal Time.zone.local(2016,4,26), delivery_dates[0]
    assert_equal Time.zone.local(2016,5,24), delivery_dates[1]

  end

  test "verify get delivery dates method 5 last" do

    posting_recurrence = PostingRecurrence.new(frequency: 5, on: true)
    posting = postings(:postingf1apples)
    mar29 = Time.zone.local(2016,3,29)    
    posting.delivery_date = mar29
    posting.order_cutoff = mar29 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + 4.months)

    assert_equal 4, delivery_dates.count

    #4/26, 5/31, 6/28, 7/26
    assert_equal Time.zone.local(2016,4,26), delivery_dates[0]
    assert_equal Time.zone.local(2016,5,31), delivery_dates[1]
    assert_equal Time.zone.local(2016,6,28), delivery_dates[2]
    assert_equal Time.zone.local(2016,7,26), delivery_dates[3]

  end

  test "verify get delivery dates method 5 not last" do

    posting_recurrence = PostingRecurrence.new(frequency: 5, on: true)
    posting = postings(:postingf1apples)
    mar15 = Time.zone.local(2016,3,15)    
    posting.delivery_date = mar15
    posting.order_cutoff = mar15 - 2.days
    posting.save
    posting_recurrence.postings << posting
    posting_recurrence.save
    
    delivery_dates = posting_recurrence.get_delivery_dates_for(posting.delivery_date, posting.delivery_date + 4.months)

    assert_equal 3, delivery_dates.count

    #4/19, 5/17, 6/21, 7/19
    assert_equal Time.zone.local(2016,4,19), delivery_dates[0]
    assert_equal Time.zone.local(2016,5,17), delivery_dates[1]
    assert_equal Time.zone.local(2016,6,21), delivery_dates[2]

  end

  test "should not create new posting when turned off" do
    do_not_create_posting_when_turned_off(1)
    do_not_create_posting_when_turned_off(2)
    do_not_create_posting_when_turned_off(3)
    do_not_create_posting_when_turned_off(4)
    do_not_create_posting_when_turned_off(5)
  end

  def do_not_create_posting_when_turned_off(frequency)

    #successfully create a new posting from a recurrence
    posting_recurrence = verify_recur_creates_one_new_posting(frequency)

    #turn off the recurrence
    posting_recurrence.turn_off

    current_num_postings = posting_recurrence.postings.count

    travel_to posting_recurrence.postings.last.order_cutoff + 1
    posting_recurrence.recur
    assert_equal current_num_postings, posting_recurrence.postings.count

    travel_back

  end

  test "should create exactly one new posting for next regular recurrence" do
    create_exactly_one_new_posting_for_next_regular_recurrence(1)
    create_exactly_one_new_posting_for_next_regular_recurrence(2)
    create_exactly_one_new_posting_for_next_regular_recurrence(3)
    create_exactly_one_new_posting_for_next_regular_recurrence(4)    
    create_exactly_one_new_posting_for_next_regular_recurrence(5)
  end

  #this method is only for testing frequency 1 - 4. not 0 (no recurrence), not 5 (monthly) and not 6 (irregular)
  def create_exactly_one_new_posting_for_next_regular_recurrence(frequency)

    if frequency <= 0
      return
    end

    verify_recur_creates_one_new_posting(frequency)

  end

  def verify_recur_creates_one_new_posting(frequency)

    posting_recurrence = create_posting_recurrence_with_posting
    posting_recurrence.frequency = frequency
    posting_recurrence.on = true
    posting_recurrence.save

    old_post = posting_recurrence.postings.last

    travel_to old_post.order_cutoff + 1    

    assert_equal 1, posting_recurrence.postings.count
    old_post.transition(:order_cutoffed)
    assert_equal 2, posting_recurrence.postings.count
    assert_equal false, old_post.live
    assert_equal true, posting_recurrence.reload.postings.last.live
    posting = posting_recurrence.postings.last

    between_posting_span_days = posting_recurrence.postings.last.delivery_date - posting_recurrence.postings.first.delivery_date

    if frequency > 0 && frequency < 5
      #verify the proper duration between week-based postings
      #the '.to_i' is cause daylight savings sometimes adds 1 hour to the calculation and i don't want to apply more brain cells 
      #to fixing it other than adding .to_i      
      assert (between_posting_span_days == frequency.weeks) ||
        (between_posting_span_days == (frequency.weeks + 1.hour)) ||
        (between_posting_span_days == (frequency.weeks - 1.hour)),
        "The failing frequency is #{frequency.to_s}"
    end

    if frequency == 5
      assert between_posting_span_days >= (28.days - 1.hour)
    end

    #since we're not now in the comitment zone window of the 'last' posting in posting_recurrence.postings
    #calling .recur shouldn't produce a new posting
    posting_recurrence.recur
    assert_equal 2, posting_recurrence.postings.count
    assert_equal posting, posting_recurrence.postings.last

    travel_to posting_recurrence.postings.first.delivery_date + 1.day + 1
    #at this point there should be two postings, one unlive, the new one live.
    #we've just fast forwarded to 1 second after midnight on the day after the first post's delivery date
    #if we call .recur right now nothing should happen. therefore we after calling .recur again we should
    #still have 2 postings, one unlive and the most recent live
    posting_recurrence.recur
    assert_equal 2, posting_recurrence.postings.count
    assert_equal posting, posting_recurrence.postings.last
    assert_equal false, posting_recurrence.postings.first.live
    assert_equal true, posting_recurrence.postings.last.live

    travel_back

    return posting_recurrence

  end

  def create_posting_recurrence_with_posting

    posting_recurrence = PostingRecurrence.new(frequency: 1, on: true)

    old_post = create_post

    posting_recurrence.postings << old_post
    posting_recurrence.save    
    assert_equal 1, posting_recurrence.postings.count
    #verify that old_post.posting_recurrence_id != nil
    assert_not old_post.posting_recurrence_id.nil?

    #since we're not between the commitment zone start and delivery date, calling .recur should not produce
    #another posting
    posting_recurrence.recur
    assert_equal 1, posting_recurrence.postings.count

    return posting_recurrence

  end

  def create_post

    delivery_date = Time.zone.now.midnight + 4.days
    if delivery_date.wday == STARTOFWEEK
      delivery_date += 1.day
    end
    order_cutoff = delivery_date - 2.days

    post = Posting.new(
      description: "my descrip",
      price: 10,
      user_id: users(:f1).id,
      product_id: products(:apples).id,
      unit_id: units(:pound).id,
      live: true,
      delivery_date: delivery_date,
      order_cutoff: order_cutoff
      )    

    post.save
    assert post.valid?

    return post

  end

  test "posting_recurrence should be valid" do
    assert @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  end

  test "posting_recurrence frequency must be valid value" do
  	@posting_recurrence.frequency = nil
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.frequency = -1
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.frequency = PostingRecurrence.frequency.last[1] + 1
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.frequency = PostingRecurrence.frequency.last[1]
    assert @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  end

end