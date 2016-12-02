
require 'integration_helper'
require 'utility/rake_helper'

class PaymentMethodsTest < IntegrationHelper

  test "automated payment engine should not process non paypal payment payables" do
    
    nuke_all_postings
    
    distributor = create_distributor
    
    producer1 = create_producer(name = "producer1 name", email = "producer1@p.com", distributor)
    producer1.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:PAYPAL])
    assert producer1.reload.get_business_interface.payment_method?(:PAYPAL)
    posting1 = create_posting(farmer = producer1, price = 10, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, units_per_case = nil, frequency = nil)
    
    producer2 = create_producer(name = "producer2 name", email = "producer2@p.com", distributor = nil, order_min = 0)
    producer2.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CASH])
    assert producer2.reload.get_business_interface.payment_method?(:CASH)
    posting2 = create_posting(farmer = producer2, price = 5, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, units_per_case = nil, frequency = nil)

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

    assert_equal 0, CreditorOrder.count
    RakeHelper.do_hourly_tasks
    assert_equal 2, CreditorOrder.count

    assert ti1.reload.state?(:COMMITTED)
    assert ti2.reload.state?(:COMMITTED)

    travel_to posting1.delivery_date + 12.hours

    assert_equal 0, PurchaseReceivable.count
    assert_equal 0, PaymentPayable.count
    assert_equal 0, CreditorObligation.count
    
    fully_fill_all_creditor_orders
    
    assert_equal 2, PurchaseReceivable.count
    assert_equal 2, PaymentPayable.count
    assert_equal 2, CreditorObligation.count

    assert_equal 1, CreditorObligation.first.payment_payables.count
    assert_equal 1, CreditorObligation.last.payment_payables.count

    assert_equal 0, CreditorObligation.first.payments.count
    assert_equal 0, CreditorObligation.last.payments.count

    assert ti1.reload.state?(:FILLED)
    assert ti2.reload.state?(:FILLED)

    assert_not CreditorObligation.first.balanced?
    assert_not CreditorObligation.last.balanced?

    travel_to posting1.delivery_date + 22.hours
    assert_equal 0, Payment.count
    RakeHelper.do_hourly_tasks
    assert_equal 1, Payment.count

    assert_equal 1, CreditorObligation.first.payments.count
    assert CreditorObligation.first.balanced?

    assert_equal 0, CreditorObligation.last.payments.count
    assert_not CreditorObligation.last.balanced?
    assert CreditorObligation.last.balance > 0.0

    assert ti1.payment_payables.first.fully_paid
    assert_not ti2.payment_payables.first.fully_paid

    travel_back

  end

end