require 'test_helper'
require 'utility/rake_helper'
require 'integration_helper'

class RakeTaskSendReceivingReportTest < IntegrationHelper
  include TestLib

  test "should send receiving report to admin" do

    nuke_all_postings
    ret = create_db_objects
    #ret looks like this:
    #{customer: bob, delivery_date: delivery_date, order_cutoffs: order_cutoffs, distributor: distributor, producers: [f1, f2, f3], postings: postings, tote_items: tis}

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel_to ret[:order_cutoffs][0]
    RakeHelper.do_hourly_tasks    
    travel_to ret[:order_cutoffs][1]
    RakeHelper.do_hourly_tasks    
    travel_to ret[:order_cutoffs][2]
    RakeHelper.do_hourly_tasks

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel_to ret[:delivery_date] + 2.hours
    RakeHelper.do_hourly_tasks
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.first

    #there were 12 postings but 4 of them didn't pass order mins etc so there should be 8 'receivable'.
    #the mail should have a table with 1 row for each posting plus 1 row for the column header labels
    assert_match "distributor Farms", mail.body.encoded
    assert_match "producer1 Farms", mail.body.encoded
    assert_match "producer3 Farms", mail.body.encoded

    assert_match "Product1", mail.body.encoded    
    assert_match "Product4", mail.body.encoded    
    assert_match "Product10", mail.body.encoded
    assert_match "Product2", mail.body.encoded
    assert_match "Product11", mail.body.encoded
    assert_match "Product3", mail.body.encoded
    assert_match "Product6", mail.body.encoded
    assert_match "Product12", mail.body.encoded

    #all these postings were in the tree but didn't pass order minimums etc so should not be in the mail
    assert_no_match "producer2 Farms", mail.body.encoded
    assert_no_match "Product5", mail.body.encoded
    assert_no_match "Product7", mail.body.encoded
    assert_no_match "Product8", mail.body.encoded
    assert_no_match "Product9", mail.body.encoded

    travel_back
    
  end

end