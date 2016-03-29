require 'test_helper'

class PostingRecurrenceTest < ActiveSupport::TestCase
  
  def setup
  	@posting_recurrence = PostingRecurrence.new(interval: 1, on: true)
  end

  test "should not create new posting when turned off" do
    do_not_create_posting_when_turned_off(1)
    do_not_create_posting_when_turned_off(2)
    do_not_create_posting_when_turned_off(3)
    do_not_create_posting_when_turned_off(4)
  end

  def do_not_create_posting_when_turned_off(interval)

    #successfully create a new posting from a recurrence
    posting_recurrence = verify_recur_creates_one_new_posting(interval)

    #turn off the recurrence
    posting_recurrence.on = false
    posting_recurrence.save

    current_num_postings = posting_recurrence.postings.count

    travel_to posting_recurrence.postings.last.commitment_zone_start + 1
    posting_recurrence.recur
    assert_equal current_num_postings, posting_recurrence.postings.count

    travel_back

  end

  test "should create exactly one new posting for next week based recurrence" do
    create_exactly_one_new_posting_for_next_week_based_recurrence(1)
    create_exactly_one_new_posting_for_next_week_based_recurrence(2)
    create_exactly_one_new_posting_for_next_week_based_recurrence(3)
    create_exactly_one_new_posting_for_next_week_based_recurrence(4)    
  end

  #this method is only for testing intervals 1 - 4. not 0 (no recurrence), not 5 (monthly) and not 6 (irregular)
  def create_exactly_one_new_posting_for_next_week_based_recurrence(interval)

    if interval <= 0
      return
    end

    if interval >= 5
      return
    end

    verify_recur_creates_one_new_posting(interval)

  end

  def verify_recur_creates_one_new_posting(interval)

    posting_recurrence = create_posting_recurrence_with_posting
    posting_recurrence.interval = interval
    posting_recurrence.on = true
    posting_recurrence.save

    old_post = posting_recurrence.postings.last

    travel_to old_post.commitment_zone_start + 1

    posting_recurrence.recur
    assert_equal 2, posting_recurrence.postings.count
    assert_equal false, old_post.live
    assert_equal true, posting_recurrence.postings.last.live
    posting = posting_recurrence.postings.last

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

    posting_recurrence = PostingRecurrence.new(interval: 1, on: true)

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
    commitment_zone_start = delivery_date - 2.days

    post = Posting.new(
      description: "my descrip",
      quantity_available: 100,
      price: 10,
      user_id: users(:f1).id,
      product_id: products(:apples).id,
      unit_category_id: unit_categories(:weight).id,
      unit_kind_id: unit_kinds(:pound).id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: commitment_zone_start
      )    

    post.save
    assert post.valid?

    return post

  end

  test "posting_recurrence should be valid" do
    assert @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  end

  test "posting_recurrence interval must be valid value" do
  	@posting_recurrence.interval = nil
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.interval = -1
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.interval = PostingRecurrence.intervals.last[1] + 1
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  	@posting_recurrence.interval = PostingRecurrence.intervals.last[1]
    assert @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  end

  test "posting_recurrence should have on set" do
  	@posting_recurrence.on = nil
    assert_not @posting_recurrence.valid?, get_error_messages(@posting_recurrence)
  end

end
