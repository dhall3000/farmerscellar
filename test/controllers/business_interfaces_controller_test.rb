require 'integration_helper'

class BusinessInterfacesControllerTest < IntegrationHelper

  test "producer should not be able to have distributor and business interface" do

    #we have puget sound food hub
    psfh = create_producer(name = "Puget Sound Food Hub", email = "john@psfh.com", distributor = nil, order_min = 0)

debugger
    xxx = 1



    #psfh moves samish bay cheese
    #create_producer(name = "Puget Sound Food Hub", email = "john@psfh.com", distributor = nil, order_min = 0)

    #later we decide to source directly from samish

  end

  test "creditor should only be able to have one business interface" do

    producer = create_producer
    assert producer.valid?
    assert producer.get_business_interface
    assert producer.business_interface
    assert_not producer.distributor

    bi_count = BusinessInterface.count
    bi2 = create_business_interface(producer, name = "Producer's Business Interface Name", order_email = "orders@farmfactory.com", payment_method = BusinessInterface.payment_methods[:CASH], payment_time = BusinessInterface.payment_times[:ONDELIVERY])
    assert_not bi2.valid?
    assert_equal bi_count, BusinessInterface.count

  end

  test "should get new" do

    #this should fail cause not logged in as admin
    get new_business_interface_path
    assert :redirect
    assert_redirected_to root_path

    log_in_as get_admin
    get new_business_interface_path
    assert :success
    assert_template 'business_interfaces/new'

  end

  test "should get create" do
    producer = create_producer
    create_business_interface(producer, name = "Pete's Milk Delivery", order_email = "pete@petesmilkdelivery.com")
  end

  test "should get create if producer not specified" do

    producer = create_producer
    log_in_as get_admin

    bi_count = BusinessInterface.count
    post business_interfaces_path, params: {
      business_interface:
      {
        name: "Pete's Milk Delivery",
        order_email: "pete@petesmilkdelivery.com",
        payment_method: BusinessInterface.payment_methods[:CASH],
        payment_time: BusinessInterface.payment_times[:ONDELIVERY]
      }
    }

    assert_equal bi_count, BusinessInterface.count
    assert_equal "BusinessInterface not created", flash.now[:danger]
    bi = assigns(:business_interface)
    assert_not bi.valid?

  end

  test "should get edit" do
    producer = create_producer
    bi = create_business_interface(producer, name = "Pete's Milk Delivery", order_email = "pete@petesmilkdelivery.com")

    log_in_as get_admin
    get edit_business_interface_path bi        
  end

  test "should get update" do
  end

  test "should get show" do
  end

  test "should get index" do
  end

end