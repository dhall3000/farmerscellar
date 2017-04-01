require 'integration_helper'

class ProducersTest < IntegrationHelper

  test "index should list producers and distributors separately" do

    nuke_all_users

    petes = create_producer(name = "Pete's Milk Delivery", email = "pete@petes.com", distributor = nil, order_min = 100)
    create_producer(name = "producer1", email = "producer1@petes.com", distributor = petes, order_min = 0)
    create_producer(name = "producer2", email = "producer2@petes.com", distributor = petes, order_min = 0)
    create_producer(name = "producer3", email = "producer3@petes.com", distributor = nil, order_min = 0)
    create_producer(name = "producer4", email = "producer4@petes.com", distributor = nil, order_min = 0)

    log_in_as get_admin
    get producers_path
    assert :success
    assert_template 'producers/index'
    producers = assigns(:producers)
    distributors = assigns(:distributors)
    assert_equal 4, producers.count
    assert_equal 1, distributors.count

  end

  test "index should clearly show when producer has no business interface" do
    nuke_all_users

    petes = create_producer(name = "Pete's Milk Delivery", email = "pete@petes.com", distributor = nil, order_min = 100)
    create_producer(name = "producer1", email = "producer1@petes.com", distributor = petes, order_min = 0)
    create_producer(name = "producer2", email = "producer2@petes.com", distributor = petes, order_min = 0)
    create_producer(name = "producer3", email = "producer3@petes.com", distributor = nil, order_min = 0)
    p4 = create_producer(name = "producer4", email = "producer4@petes.com", distributor = nil, order_min = 0)

    log_in_as get_admin
    get producers_path
    assert :success
    assert_template 'producers/index'
    producers = assigns(:producers)
    distributors = assigns(:distributors)
    assert_equal 4, producers.count
    assert_equal 1, distributors.count
    #verify there are no warnings on the index page. that is, all producers have an associated businessinterface
    assert_select 'a.alert-danger', {text: p4.farm_name, count: 0}

    #now p4's bi gets nuked
    bi_count = BusinessInterface.count
    delete business_interface_path(p4.business_interface)
    assert_response :redirect
    assert_equal bi_count - 1, BusinessInterface.count

    #now verify bi index page shows that p4 has a problem. that is, no bi
    get producers_path
    assert_response :success
    assert_template 'producers/index'
    assert_select 'a.alert-danger', {text: p4.farm_name, count: 1}

  end

  test "index should clearly show when producer has business interface and distributor" do

    nuke_all_users

    petes = create_producer(name = "Pete's Milk Delivery", email = "pete@petes.com", distributor = nil, order_min = 100)
    p1 = create_producer(name = "producer1", email = "producer1@petes.com", distributor = petes, order_min = 0)
    p2 = create_producer(name = "producer2", email = "producer2@petes.com", distributor = petes, order_min = 0)
    p3 = create_producer(name = "producer3", email = "producer3@petes.com", distributor = nil, order_min = 0)
    p4 = create_producer(name = "producer4", email = "producer4@petes.com", distributor = nil, order_min = 0)
debugger
    log_in_as get_admin
    get producers_path
    assert :success
    assert_template 'producers/index'
    producers = assigns(:producers)
    distributors = assigns(:distributors)
    assert_equal 4, producers.count
    assert_equal 1, distributors.count
    #verify there are no warnings on the index page. that is, all producers have an associated businessinterface
    assert_select 'a.alert-danger', {text: p4.farm_name, count: 0}

    #now p4's bi gets nuked
    bi_count = BusinessInterface.count
    delete business_interface_path(p4.business_interface)
    assert_response :redirect
    assert_equal bi_count - 1, BusinessInterface.count

    #now verify bi index page shows that p4 has a problem. that is, no bi
    get producers_path
    assert_response :success
    assert_template 'producers/index'
    assert_select 'a.alert-danger', {text: p4.farm_name, count: 1}

  end

  test "index should clearly show when distributor has no business interface" do

  end

  test "show should say clearly what problem is when no business interface associated" do
  end

  test "show should say clearly what problem is when business interface and distributor exists" do
  end

end