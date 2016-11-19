require 'test_helper'
require 'integration_helper'
require 'utility/rake_helper'

class PaymentMethodsTest < IntegrationHelper

  test "automated payment engine should not process non paypal payment payables" do
    
    nuke_all_postings
    
    distributor = create_distributor
    
    producer1 = create_producer(name = "producer1 name", email = "producer1@p.com", distributor)
    producer1.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:PAYPAL])
    assert producer1.reload.get_business_interface.payment_method?(:PAYPAL)
    posting1 = create_posting_recurrence(farmer = producer1, price = 10).current_posting
    
    producer2 = create_producer(name = "producer2 name", email = "producer2@p.com", distributor = nil, order_min = 0)
    producer2.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CASH])
    assert producer2.reload.get_business_interface.payment_method?(:CASH)
    posting2 = create_posting_recurrence(farmer = producer2, price = 5).current_posting

    bob = create_new_customer("bob", "bob@b.com")
    ti1 = create_tote_item(bob, posting1, quantity = 10)        
    ti2 = create_tote_item(bob, posting2, quantity = 10)    

    assert ti1.state?(:ADDED)
    assert ti2.state?(:ADDED)

    create_one_time_authorization_for_customer(bob)
    assert ti1.reload.state?(:AUTHORIZED)
    assert ti2.reload.state?(:AUTHORIZED)

    assert_equal posting1.delivery_date, posting2.delivery_date
    travel_to posting1.commitment_zone_start

    RakeHelper.do_hourly_tasks

    assert ti1.reload.state?(:COMMITTED)
    assert ti2.reload.state?(:COMMITTED)

    travel_to posting1.delivery_date + 12.hours
    assert_equal 0, PurchaseReceivable.count
    fully_fill_all_creditor_orders
    assert_equal 2, PurchaseReceivable.count

    assert ti1.reload.state?(:FILLED)
    assert ti2.reload.state?(:FILLED)

    travel_to posting1.delivery_date + 22.hours
    assert_equal 0, PaymentPayable.count
    RakeHelper.do_hourly_tasks
    assert_equal 2, PaymentPayable.count

    assert ti1.payment_payables.first.fully_paid
    assert_not ti2.payment_payables.first.fully_paid

    travel_back

  end

end