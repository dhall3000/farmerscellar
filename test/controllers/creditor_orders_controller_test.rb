require 'test_helper'
require 'utility/rake_helper'

class CreditorOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do

    nuke_all_postings
    ret = create_db_objects
    #ret looks like this:
    #{customer: bob, delivery_date: delivery_date, order_cutoffs: order_cutoffs, distributor: distributor, producers: [f1, f2, f3], postings: postings, tote_items: tis}

    assert_equal 0, CreditorOrder.count

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel_to ret[:order_cutoffs][0]
    RakeHelper.do_hourly_tasks    
    travel_to ret[:order_cutoffs][1]
    RakeHelper.do_hourly_tasks    
    travel_to ret[:order_cutoffs][2]
    RakeHelper.do_hourly_tasks

    assert_equal 3, CreditorOrder.count

    log_in_as(users(:a1))
    get creditor_orders_path
    assert_response :success

    travel_back
    
  end

end