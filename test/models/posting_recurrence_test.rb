require 'test_helper'

class PostingRecurrenceTest < ActiveSupport::TestCase
  
  def setup
  	@posting_recurrence = PostingRecurrence.new(interval: 1, on: true)
  end

  test "should create exactly one new posting for next week" do
    posting_recurrence = PostingRecurrence.new(interval: 1, on: true)

    delivery_date = Time.zone.now.midnight + 4.days
    commitment_zone_start = delivery_date - 2.days

    old_post = Posting.new(
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

    old_post.save
    assert old_post.valid?

    posting_recurrence.postings << old_post
    posting_recurrence.save    
    assert_equal 1, posting_recurrence.postings.count
    #verify that old_post.posting_recurrence_id != nil
    assert_not old_post.posting_recurrence_id.nil?

    #since we're not between the commitment zone start and delivery date, calling .recur should not produce
    #another posting
    posting_recurrence.recur
    assert_equal 1, posting_recurrence.postings.count

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

    travel_back
    
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
