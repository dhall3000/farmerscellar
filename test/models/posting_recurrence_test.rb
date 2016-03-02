require 'test_helper'

class PostingRecurrenceTest < ActiveSupport::TestCase
  
  def setup
  	@posting_recurrence = PostingRecurrence.new(interval: 1, on: true)
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
