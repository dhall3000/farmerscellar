require 'integration_helper'

class BusinessInterfacesControllerTest < IntegrationHelper

  test "belong to producers should exclude patrons of a distributor" do

    #explanation: a producer can't have a business_interface and a distributor. that is a foul. so when we are creating a new BI we have a dropdown
    #list of the eligible producers. this list of eligibles should only include producers who have neither distributor nor BI

    nuke_all_users

    distributor = create_distributor("pete's", "pete@petesmilkdelivery.com")
    assert distributor.valid?
    assert distributor.business_interface
    assert distributor.business_interface.valid?

    grace = create_producer("grace harbor farms", "tim@ghf.com", distributor, order_min = 0, create_default_business_interface = false)
    pureeire = create_producer("pure eire dairy", "richard@pe.com", distributor, order_min = 0, create_default_business_interface = false)

    new_farm = create_producer("bob's turkey ranch", "bob@turkeyranch.com", nil, order_min = 0, create_default_business_interface = false)
    assert new_farm.valid?
    assert_not new_farm.business_interface
    assert new_farm.get_business_interface.nil?

    log_in_as get_admin
    get new_business_interface_path
    assert_response :success
    assert_template 'business_interfaces/new'

    producers = assigns(:producers)

    assert_equal 1, producers.where(id: new_farm).count

    #these belong to the distributor so shouldn't be visible in the 'eligibles' list
    assert_not producers.where(id: grace).any?
    assert_not producers.where(id: pureeire).any?

    #there should only be one eligible producer to belong_to
    assert_equal 1, producers.count

  end

  test "producer should not be able to have distributor and business interface" do

    #we have puget sound food hub
    psfh = create_producer(name = "Puget Sound Food Hub", email = "john@psfh.com", distributor = nil, order_min = 0)
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

  test "should not create if producer not specified" do

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
    producer = create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 0, create_default_business_interface = false)
    bi = create_business_interface(producer, name = "Pete's Milk Delivery", order_email = "pete@petesmilkdelivery.com")

    log_in_as get_admin
    get edit_business_interface_path bi        
  end

end