require 'integration_helper'

class PostingRecurrenceIntegrationTest < IntegrationHelper
  test "should turn recurrence on and make posting live when recur is checked after a long pause" do
    #the scenario here is say i'm running a producer's postings and then i need to stop for whatever reason. then, perhaps a long time
    #down the road i want to start back up. i want to be able to just go in to the producer account and with the check of a button it automatically kicks
    #the recurrence in the tail and starts making recurring postings

    nuke_all_postings
    wednesday_next_week = get_next_wday_after(wday = 3, days_from_now = 7)
    original_posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = wednesday_next_week + 2.days, order_cutoff = wednesday_next_week, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil, important_notes = nil, important_notes_body = nil)
    pr = original_posting.posting_recurrence
    farmer = original_posting.user

    assert original_posting.valid?
    travel_to original_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 2, pr.reload.postings.count
    
    travel_to pr.current_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 3, pr.reload.postings.count

    travel_to pr.current_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    assert_equal 4, pr.reload.postings.count

    #now we have a good historical postings series.log in as the farmer and turn this recurrence off
    log_in_as farmer
    get edit_posting_path pr.current_posting
    assert_response :success
    assert_template 'postings/edit'
    #verify live and recur checkboxes are visible and unchecked
    assert_select 'input#posting_live[value=?]', "1"
    assert pr.reload.on
    assert_select 'input#posting_posting_recurrence_on[value=?]', "1"
    assert_select 'input#posting_posting_recurrence_on[checked=?]', "checked"

    patch posting_path(pr.current_posting), params: {posting: {live: false, posting_recurrence: {on: 0}}}
    assert_response :redirect
    assert_redirected_to farmer

    pr.reload

    assert_not pr.on
    assert_not pr.current_posting.live

    last_delivery_date_before_pause = pr.current_posting.delivery_date

    #ok, we've already turned off the recurrence. but now we're going to the order cutoff of the last posting in the series
    #to do hourly tasks. this will transition the last posting's state away from OPEN which is important so that we can later
    #verify when we unpause the recurrence that the fresh new posting's state is OPEN
    travel_to pr.current_posting.order_cutoff
    RakeHelper.do_hourly_tasks
    pr.current_posting.reload
    assert_not_equal Posting.states[:OPEN], pr.current_posting.state

    #now go to a time far out in the future that's right in the middle of what should be the committment zone
    #thursday
    travel_to pr.current_posting.order_cutoff + 1.day + 28.days

    #now farmer logs back in and turns on the recurrence
    log_in_as farmer
    get edit_posting_path pr.current_posting.reload
    assert_response :success
    assert_template 'postings/edit'
    #verify live and recur checkboxes are visible and unchecked
    assert_select 'input#posting_live[value=?]', "1"
    assert_not pr.reload.on
    #this value affirmation of "1" might seem a little wonky but string search "gotcha" here and you'll see why: http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-check_box
    #but here's how it works. with the checkbox, rails puts two <input>s, one with the checked value and one without.
    assert_select 'input#posting_posting_recurrence_on[value=?]', "1"
    assert_select 'input#posting_posting_recurrence_on[checked]', false

    #so now we've verified the farmer is looking at the edit page of the posting inquestion and sees a checkbox both for live and recur

    #now user turns the recurrence back on
    patch posting_path(pr.current_posting), params: {posting: {live: true, posting_recurrence: {on: 1}}}
    assert_response :redirect
    assert_redirected_to farmer
    #recurrence should be on
    assert pr.reload.on
    #current_posting should be on
    cp = pr.current_posting
    assert cp.live
    #current_posting's delivery_date and order cutoff should be in the future
    assert cp.delivery_date > Time.zone.now
    assert cp.order_cutoff > Time.zone.now
    #delivery_date should be a friday
    assert_equal 5, cp.delivery_date.wday
    #order_cutoff should be wednesday
    assert_equal 3, cp.order_cutoff.wday

    #delivery_dates should be spaced 35 days
    assert_equal last_delivery_date_before_pause + 35.days, cp.delivery_date    
    assert_equal last_delivery_date_before_pause - 2.days + 35.days, cp.order_cutoff

    assert cp.state?(:OPEN)

    travel_back
    
  end
end