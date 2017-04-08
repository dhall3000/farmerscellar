require 'model_test_ancestor'

class BusinessInterfaceTest < ModelTestAncestor

  test "can not belong to producer that has a distributor" do
    distributor = create_producer(name = "distributor name", email = "distributor@p.com")
    producer = create_producer(name = "producer name", email = "producer@p.com", distributor, 0, create_default_business_interface = false)

    assert distributor.valid?
    assert producer.valid?
    assert distributor.get_business_interface
    assert_not producer.business_interface
    assert producer.distributor

    bi = create_business_interface(producer)

    assert_not bi.valid?
    assert_not producer.reload.business_interface
  end

end