require 'integration_helper'

class HeaderTest < IntegrationHelper

  test "number of active authorized subscriptions should be accurate" do
    bob = create_user
    #should report 0
    log_in_as bob
    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_template '/'

    #verify no subscriptions indicated
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    #add a non-recurring tote item
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil)
    ti = create_tote_item(bob, posting, quantity = 1)
    assert ti.valid?
    assert_response :redirect
    follow_redirect!
    #verify tote item shows in header
    assert_select 'span.glyphicon-shopping-cart ~ span.header-object-count', "1"
    #verify we do not see a subscription
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    #add sx to tote
    ti2 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should report 0
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
    assert_equal 0, num_authorized_subscriptions_for(bob)
    #create authorization
    create_rt_authorization_for_customer(bob)
    get root_path
    #should report 1    
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"
    #add another subscription to tote
    ti3 = create_tote_item(bob, posting, quantity = 1, frequency = 1)
    follow_redirect!
    #should still only be one authorized subscription
    assert_equal 1, get_authorized_subscriptions_for(bob).count
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"
    #now authorize and then verify there are two subscriptions
    create_rt_authorization_for_customer(bob)
    get root_path
    assert_equal 2, num_authorized_subscriptions_for(bob)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "2"
    #cancel first sx
    ti2.subscription.update(on: false)
    get root_path
    #should report 1
    assert_equal 1, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', "1"    
    #cancel second sx
    ti3.subscription.update(on: false)
    get root_path
    #should report 0
    assert_equal 0, num_authorized_subscriptions_for(bob.reload)
    assert_select 'span.glyphicon-repeat ~ span.header-object-count', ""
  end

end