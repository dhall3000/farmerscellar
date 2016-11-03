require 'test_helper'
require 'integration_helper'
require 'utility/rake_helper'

class SubscriptionMonthlyRecurrenceTest < IntegrationHelper

  #I am now verifying the correct implementation of the monthly subscription way after the weeklies were implemented
  #that's what all these tests are for

  test "general test" do

    nuke_all_postings
    nuke_all_users

    monthly_recurrence_frequency = 5
    subscription_frequency = 1 #every recurrence delivery
    posting_recurrence = create_posting_recurrence
    posting_recurrence.update(frequency: monthly_recurrence_frequency)

    posting = posting_recurrence.current_posting

    user = create_user("bob", "bob@b.com")
    quantity = 2

    travel_to posting_recurrence.current_posting.commitment_zone_start

    num_tote_items_start = user.tote_items.count    
    num_tote_items_end = user.tote_items.count + 4

    while user.tote_items.count < num_tote_items_end

      top_of_hour = Time.zone.now.min == 0

      if top_of_hour
        RakeHelper.do_hourly_tasks        
      end

      posting_recurrence.reload

      if posting_recurrence.postings.count >= 2 && user.tote_items.count == num_tote_items_start        
        add_tote_item(user, posting_recurrence.current_posting, quantity, subscription_frequency)
        create_rt_authorization_for_customer(user)
      end                

      #if you draw out a postings series you'll see that the last inthe series is always open because the moment time enters the 
      #commitment zone of the last we generate the next posting, which becomes the 'last', which is OPEN
      assert posting_recurrence.current_posting.state?(:OPEN)
      assert posting_recurrence.current_posting.live

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

      travel 1.day

    end

    travel_back

    do_posting_spacing(posting_recurrence)
    do_tote_item_spacing(posting_recurrence)

  end

  test "should generate tote item if when a bi weekly subscription is paused producer changes delivery day then user unpauses subscription" do
    #i'm going to save implementing this for a later time. the test name is a copy from integration/subscription_test so can key off that
    #when the time is right    
  end

  test "when weekly producer changes wday with a bi weekly subscriber should create tote item spaced roughly two weeks apart" do
    #i'm going to save implementing this for a later time. the test name is a copy from integration/subscription_test so can key off that
    #when the time is right    
  end

  test "should give immediate next delivery date as skip date option" do
  end
  
  test "should skip immediate next delivery date" do  
  end

  test "item nuked from tote should show checked skip date" do
  end

  test "skip dates programming for oddball recurrence and subscription schedules" do
  end

  test "should skip immediate next delivery date and next then unskip only indd" do
  end

  test "should skip immediate next delivery date and next then unskip only next" do
  end

  test "should unskip immediate next delivery date" do
  end

  test "should not generate tote items for skip dates" do
  end

  test "should not generate tote items after subscription is paused" do
  end

end