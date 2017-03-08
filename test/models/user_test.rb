require 'test_helper'
require 'utility/rake_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    puts "Test method: #{self.method_name}"
    @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar", zip: 98033, account_type: 0)
    @f6 = users(:f6)
    @f7 = users(:f7)
    @f8 = users(:f8)
    @d1 = users(:d1)
  end

  #what if you have a producer that has no distributor. can you call producer.outbound_order_report(postings_at_order_cutoff) on it and have it do the right thing?
  test "should return proper orderable report when distributor postings reporter called on a producer with no distributor" do

    nuke_all_postings

    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com")
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    #has lots of order cutoffs
    delivery_date1 = get_delivery_date(days_from_now = 7)
    delivery_date2 = get_delivery_date(days_from_now = 14)

    delivery_date1_postings = []
    delivery_date2_postings = []

    assert_equal 0, Posting.count
   
    #producer 1 postings, order min: $20
    price_carrots = 3.00
    posting_carrots = create_posting(producer1, price_carrots, product = products(:carrots), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_carrots
    
    price_milk = 4.00
    posting_milk = create_posting(producer1, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    assert_equal 2, Posting.count

    #customers
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")
    sam = create_user("sam", "sam@s.com")

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)
    ti_chris_carrots = create_tote_item(chris, posting_carrots, quantity = 12)

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)
    create_one_time_authorization_for_customer(chris)
    
    report = producer1.outbound_order_report(posting_carrots.order_cutoff)    
    producer1_net_value = 49.32    
    assert_equal producer1_net_value, report[:order_value_producer_net]

  end

  test "should find orderable postings when distributor has lots of postings with various order cutoffs with case and order minimums are met" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com")
    producer2.distributor = oxbow
    producer2.save

    #has lots of order cutoffs
    delivery_date1 = get_delivery_date(days_from_now = 7)
    delivery_date2 = get_delivery_date(days_from_now = 14)

    delivery_date1_postings = []
    delivery_date2_postings = []

    assert_equal 0, Posting.count

    price_celery = 1.00
    posting_celery = create_posting(oxbow, price_celery, product = products(:celery), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_celery
    czs1 = posting_celery.order_cutoff

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.order_cutoff
    
    #producer 1 postings, order min: $20
    price_carrots = 3.00
    posting_carrots = create_posting(producer1, price_carrots, product = products(:carrots), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_carrots
    
    price_milk = 4.00
    posting_milk = create_posting(producer1, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    #producer2 postings
    price_beef = 5.00
    posting_beef = create_posting(producer2, price_beef, product = products(:beef), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_beef
    posting_beef.update(units_per_case: 10)
    
    price_milk = 6.00
    posting_milk = create_posting(producer2, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    assert_equal 6, Posting.count

    #customers
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")
    sam = create_user("sam", "sam@s.com")

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_sam_celery = create_tote_item(sam, posting_celery, quantity = 2)

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)
    ti_chris_carrots = create_tote_item(chris, posting_carrots, quantity = 12)

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 12, num_cases: 1, contribution: $50
    ti_sam_beef = create_tote_item(sam, posting_beef, quantity = 6)
    ti_chris_beef = create_tote_item(chris, posting_beef, quantity = 6)

    #-----------------------------------------------------------------------------------------------

    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 3)
    ti_sam_apples = create_tote_item(sam, posting_apples, quantity = 2)

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)
    create_one_time_authorization_for_customer(chris)

    #get producer net by first commitment zone
    first_czs_oxbow_net = oxbow.outbound_order_value_producer_net(czs1)
    #get producer net by postings
    first_postings_distributor_net = get_outbound_order_value_producer_net(delivery_date1_postings)
    #verify producer nets match
    assert_equal first_czs_oxbow_net, first_postings_distributor_net    
    #verify correct oxbow producer net value
    assert_equal 99.57, first_czs_oxbow_net
    #verify correct producer1 producer net value
    producer1_net_value = 49.32
    assert_equal producer1_net_value, producer1.outbound_order_value_producer_net(czs1)
    #verify correct producer2 producer net value
    producer2_net_value = 45.70
    assert_equal producer2_net_value, producer2.outbound_order_value_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, outbound_order_value_producer_net: 0}

    report = oxbow.outbound_order_report(delivery_date1_postings.first.order_cutoff)
    assert_equal first_czs_oxbow_net, report[:order_value_producer_net]

    report = producer1.outbound_order_report(posting_carrots.order_cutoff)
    assert_equal producer1_net_value, report[:order_value_producer_net]

    report = producer2.outbound_order_report(posting_beef.order_cutoff)
    assert_equal producer2_net_value, report[:order_value_producer_net]

  end

  def get_outbound_order_value_producer_net(postings)

    outbound_order_value_producer_net = 0

    if postings.nil?
      return outbound_order_value_producer_net
    end

    postings.each do |posting|
      outbound_order_value_producer_net = (outbound_order_value_producer_net + posting.reload.outbound_order_value_producer_net).round(2)
    end

    return outbound_order_value_producer_net

  end

  test "should find orderable postings when distributor has lots of postings with various order cutoffs and minimums are met" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com")
    producer2.distributor = oxbow
    producer2.save

    #has lots of order cutoffs
    delivery_date1 = get_delivery_date(days_from_now = 7)
    delivery_date2 = get_delivery_date(days_from_now = 14)

    delivery_date1_postings = []
    delivery_date2_postings = []

    assert_equal 0, Posting.count

    price_celery = 1.00
    posting_celery = create_posting(oxbow, price_celery, product = products(:celery), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_celery
    czs1 = posting_celery.order_cutoff

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.order_cutoff
    
    #producer 1 postings, order min: $20
    price_carrots = 3.00
    posting_carrots = create_posting(producer1, price_carrots, product = products(:carrots), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_carrots
    
    price_milk = 4.00
    posting_milk = create_posting(producer1, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    #producer2 postings
    price_beef = 5.00
    posting_beef = create_posting(producer2, price_beef, product = products(:beef), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_beef
    posting_beef.update(units_per_case: 10)
    
    price_milk = 6.00
    posting_milk = create_posting(producer2, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    assert_equal 6, Posting.count

    #customers
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")
    sam = create_user("sam", "sam@s.com")

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3) #
    ti_sam_celery = create_tote_item(sam, posting_celery, quantity = 2)

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 6)
    ti_chris_carrots = create_tote_item(chris, posting_carrots, quantity = 12)

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 6, contribution: $0
    ti_sam_beef = create_tote_item(sam, posting_beef, quantity = 3)
    ti_chris_beef = create_tote_item(chris, posting_beef, quantity = 3)

    #-----------------------------------------------------------------------------------------------
    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 3)
    ti_sam_apples = create_tote_item(sam, posting_apples, quantity = 2)

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)
    create_one_time_authorization_for_customer(chris)

    #get producer net by first commitment zone
    first_czs_oxbow_net = oxbow.reload.outbound_order_value_producer_net(czs1)
    #get producer net by postings    
    first_postings_distributor_net = get_outbound_order_value_producer_net(delivery_date1_postings)
    #verify producer nets match

    assert_equal first_czs_oxbow_net, first_postings_distributor_net    
    #verify correct oxbow producer net value
    assert_equal 53.87, first_czs_oxbow_net
    #verify correct producer1 producer net value
    producer1_net_value = 49.32
    assert_equal producer1_net_value, producer1.outbound_order_value_producer_net(czs1)
    #verify correct producer2 producer net value
    assert_equal 0, producer2.outbound_order_value_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, outbound_order_value_producer_net: 0}

    report = oxbow.outbound_order_report(delivery_date1_postings.first.order_cutoff)
    assert_equal first_czs_oxbow_net, report[:order_value_producer_net]

    report = producer1.outbound_order_report(posting_carrots.order_cutoff)
    assert_equal producer1_net_value, report[:order_value_producer_net]

    report = producer2.outbound_order_report(posting_beef.order_cutoff)
    assert_equal 0, report[:order_value_producer_net]

  end

  test "should return proper producer net value for postings when distributor has lots of postings with various order cutoffs" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com")
    producer2.distributor = oxbow
    producer2.save

    #has lots of order cutoffs
    delivery_date1 = get_delivery_date(days_from_now = 7)
    delivery_date2 = get_delivery_date(days_from_now = 14)

    delivery_date1_postings = []
    delivery_date2_postings = []

    assert_equal 0, Posting.count

    price_celery = 1.00
    posting_celery = create_posting(oxbow, price_celery, product = products(:celery), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_celery
    czs1 = posting_celery.order_cutoff

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.order_cutoff
    
    #producer 1 postings, order min: $20
    price_carrots = 3.00
    posting_carrots = create_posting(producer1, price_carrots, product = products(:carrots), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_carrots
    
    price_milk = 4.00
    posting_milk = create_posting(producer1, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    #producer2 postings
    price_beef = 5.00
    posting_beef = create_posting(producer2, price_beef, product = products(:beef), unit = units(:pound), delivery_date1)
    delivery_date1_postings << posting_beef
    posting_beef.update(units_per_case: 10)
    
    price_milk = 6.00
    posting_milk = create_posting(producer2, price_milk, product = products(:milk), unit = units(:gallon), delivery_date2)
    delivery_date2_postings << posting_milk

    assert_equal 6, Posting.count

    #customers
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")
    sam = create_user("sam", "sam@s.com")

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_sam_celery = create_tote_item(sam, posting_celery, quantity = 2)

    #tote items producer1 1, price 3.00, order min: $20, contribution: $15
    ti_bob_carrots = create_tote_item(bob, posting_carrots, quantity = 3)
    ti_chris_carrots = create_tote_item(chris, posting_carrots, quantity = 2)

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 6, contribution: $0
    ti_sam_beef = create_tote_item(sam, posting_beef, quantity = 3)
    ti_chris_beef = create_tote_item(chris, posting_beef, quantity = 3)

    #-----------------------------------------------------------------------------------------------

    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 3)
    ti_sam_apples = create_tote_item(sam, posting_apples, quantity = 2)

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 3)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)
    create_one_time_authorization_for_customer(chris)

    #oxbow has om $50 and only has gross sales of $5. producer1 has om $20 and only has gross sales of $13.75
    #producer2 has no om but does have case size of 10 and only 6 units sold
    #so each of the three producers should have individual outbound order of $0 which means the sum is also $0

    assert_equal 1, producer1.postings.where(order_cutoff: czs1).count
    p1p = producer1.postings.where(order_cutoff: czs1).first
    assert_equal 13.70, p1p.outbound_order_value_producer_net
    assert_equal 20, producer1.order_minimum_producer_net
    assert_equal 0, producer1.outbound_order_value_producer_net(czs1)

    assert_equal 1, producer2.postings.where(order_cutoff: czs1).count
    p2p = producer2.postings.where(order_cutoff: czs1).first
    assert_equal 10, p2p.units_per_case
    assert_equal 6, p2p.total_quantity_authorized_or_committed
    assert_equal 0, producer2.outbound_order_value_producer_net(czs1)

    assert_equal 4.55, oxbow.inbound_order_value_producer_net(czs1)
    assert_equal 0, oxbow.outbound_order_value_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, outbound_order_value_producer_net: 0}
    report = oxbow.outbound_order_report(czs1)
    assert_equal 0, report[:order_value_producer_net]

    report = producer1.outbound_order_report(p1p.order_cutoff)
    assert_equal 0, report[:order_value_producer_net]

    report = producer2.outbound_order_report(p2p.order_cutoff)
    assert_equal 0, report[:order_value_producer_net]

  end

  test "should return proper value for orderable postings when producer has lots of postings with various order cutoffs" do

    producer = create_producer("producer", "producer@p.com")

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    price_milk = 1.00
    posting_milk = create_posting(producer, price_milk, product = products(:milk))
    #change this order cutoff time so that it's not included in the order value computation
    posting_milk.update(order_cutoff: posting_milk.order_cutoff - 1)
    
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")
    sam = create_user("sam", "sam@s.com")

    #create tote items for all postings
    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)
    ti_sam_celery = create_tote_item(sam, posting_celery, quantity = 9)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)
    ti_sam_apples = create_tote_item(sam, posting_apples, quantity = 6)

    ti_bob_milk = create_tote_item(bob, posting_milk, quantity = 1)
    ti_chris_milk = create_tote_item(chris, posting_milk, quantity = 2)
    ti_sam_milk = create_tote_item(sam, posting_milk, quantity = 3)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(sam)
    create_one_time_authorization_for_customer(chris)

    expected_celery_posting_value = 41.04
    expected_apples_posting_value = 21.96
    expected_order_value = expected_celery_posting_value + expected_apples_posting_value
    assert_equal 63, expected_order_value

    assert_equal expected_celery_posting_value, posting_celery.reload.inbound_order_value_producer_net
    assert_equal expected_apples_posting_value, posting_apples.reload.inbound_order_value_producer_net

    czs = posting_celery.order_cutoff
    producer_net = producer.outbound_order_value_producer_net(czs)

    assert_equal expected_order_value, producer_net

  end

  test "should submit orders when producer has no order minimum" do

    producer = create_producer("producer", "producer@p.com")

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert report[:postings_order_requirements_met].include?(posting_celery)
    assert report[:postings_order_requirements_met].include?(posting_apples)

    assert_equal 0, report[:postings_order_requirements_unmet].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:order_value_producer_net]

  end

  test "should submit orders when total producer net meets producer order minimum" do
    producer = create_producer("producer", "producer@p.com")

    order_minimum = 30
    producer.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, producer.reload.order_minimum_producer_net

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert report[:postings_order_requirements_met].include?(posting_celery)
    assert report[:postings_order_requirements_met].include?(posting_apples)
    assert_equal 0, report[:postings_order_requirements_unmet].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:order_value_producer_net]
  end

  test "should not submit orders when total producer net is below producer order minimum" do
    producer = create_producer("producer", "producer@p.com")

    order_minimum = 32
    producer.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, producer.reload.order_minimum_producer_net

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert_equal 0, report[:postings_order_requirements_met].count
    assert report[:postings_order_requirements_unmet].include?(posting_celery)
    assert report[:postings_order_requirements_unmet].include?(posting_apples)

    #verify total order amount    
    assert_equal 0, report[:order_value_producer_net]
  end

  test "should submit orders when distributor has no order minimum" do
    distributor = create_producer("distributor", "distributor@d.com")
    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)
    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.reload.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.reload.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert report[:postings_order_requirements_met].include?(posting_celery)
    assert report[:postings_order_requirements_met].include?(posting_apples)

    assert_equal 0, report[:postings_order_requirements_unmet].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:order_value_producer_net]
  end

  test "should submit orders when producer orders meet distributor order minimum" do
    distributor = create_producer("distributor", "distributor@d.com")
    order_minimum = 30
    distributor.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, distributor.reload.order_minimum_producer_net
    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)
    
    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.reload.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.reload.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert report[:postings_order_requirements_met].include?(posting_celery)
    assert report[:postings_order_requirements_met].include?(posting_apples)
    assert_equal 0, report[:postings_order_requirements_unmet].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:order_value_producer_net]
  end
  
  test "should not submit orders when producer orders do not meet distributor order minimum" do
    distributor = create_producer("distributor", "distributor@d.com")
    order_minimum = 32
    distributor.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, distributor.reload.order_minimum_producer_net
    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert_equal 0, report[:postings_order_requirements_met].count

    assert report[:postings_order_requirements_unmet].include?(posting_celery)
    assert report[:postings_order_requirements_unmet].include?(posting_apples)

    #verify total order amount    
    assert_equal 0, report[:order_value_producer_net]
  end

  test "should exclude producer from distributor order submission when producer order minimum is not met" do
    distributor = create_producer("distributor", "distributor@d.com")
    distributor_order_minimum = 10
    distributor.update(order_minimum_producer_net: distributor_order_minimum)
    assert_equal distributor_order_minimum, distributor.reload.order_minimum_producer_net

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save
    producer1_order_minimum = 25
    producer1.update(order_minimum_producer_net: producer1_order_minimum)
    assert_equal producer1_order_minimum, producer1.reload.order_minimum_producer_net

    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert_equal 1, report[:postings_order_requirements_met].count
    assert_equal posting_apples, report[:postings_order_requirements_met].last

    assert_equal 1, report[:postings_order_requirements_unmet].count
    assert_equal posting_celery, report[:postings_order_requirements_unmet].last

    #verify total order amount    
    assert_equal expected_producer_net_apples, report[:order_value_producer_net]
  end

  test "should submit orders properly when distributor is itself a producer" do
    distributor = create_producer("distributor", "distributor@d.com")
    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_milk = 10
    posting_milk = create_posting(distributor, price_milk, product = products(:milk))

    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com")
    chris = create_user("chris", "chris@c.com")

    ti_bob_milk = create_tote_item(bob, posting_milk, quantity = 1)

    ti_bob_celery = create_tote_item(bob, posting_celery, quantity = 3)
    ti_chris_celery = create_tote_item(chris, posting_celery, quantity = 6)

    ti_bob_apples = create_tote_item(bob, posting_apples, quantity = 2)
    ti_chris_apples = create_tote_item(chris, posting_apples, quantity = 4)

    create_one_time_authorization_for_customer(bob)
    create_one_time_authorization_for_customer(chris)

    #verify inbound_order_value_producer_net value
    gross_milk = price_milk
    commission_per_unit_milk = 0.50
    payment_processor_fee_unit_milk = 0.35
    producer_net_unit_milk = (price_milk - commission_per_unit_milk - payment_processor_fee_unit_milk).round(2)
    assert_equal 9.15, producer_net_unit_milk
    assert_equal producer_net_unit_milk, posting_milk.reload.producer_net_unit
    expected_producer_net_milk = 9.15
    assert_equal expected_producer_net_milk, posting_milk.inbound_order_value_producer_net    

    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.reload.producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.reload.producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net + posting_milk.inbound_order_value_producer_net
    expected_producer_net = 40.65
    assert_equal expected_producer_net, producer_net

    #outbound_order_report(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.outbound_order_report(posting_celery.order_cutoff)
    #verify all postings returned
    assert_equal 0, report[:postings_order_requirements_unmet].count
    assert_equal 3, report[:postings_order_requirements_met].count
        
    products_included = []
    report[:postings_order_requirements_met].each do |posting|
      products_included << posting.product.name
    end

    assert products_included.include?(posting_milk.product.name)
    assert products_included.include?(posting_celery.product.name)
    assert products_included.include?(posting_apples.product.name)

    #verify total order amount    
    assert_equal expected_producer_net, report[:order_value_producer_net]
  end

  test "producer without distributor should have business interface" do
    assert_not @f8.get_business_interface.nil?
    assert_equal "f8order_email@f.com", @f8.get_business_interface.order_email
  end

  test "distributor should have multiple producers" do
    assert_equal 2, @d1.producers.count
    assert_equal 1, @d1.producers.where(email: @f6.email).count
    assert_equal 1, @d1.producers.where(email: @f7.email).count
  end

  test "producer should have distributor" do
    assert @f6.get_business_interface
  end

  test "producer should be able to access distributor order email address" do
    assert @f6.get_business_interface
    assert_equal "d1order_email@d.com", @f6.get_business_interface.order_email
  end

  test "should get tote items to pickup" do

    c1 = users(:c1)

    order_cutoffs = []

    c1.tote_items.each do |tote_item|            
      tote_item.update(state: ToteItem.states[:ADDED])
      tote_item.transition(:customer_authorized)
      assert tote_item.reload.state?(:AUTHORIZED)
      order_cutoffs << tote_item.posting.order_cutoff
    end

    order_cutoffs = order_cutoffs.uniq.sort
    order_cutoffs.each do |order_cutoff|
      travel_to order_cutoff
      RakeHelper.do_hourly_tasks      
    end

    c1.reload

    c1.tote_items.each do |tote_item|
      assert tote_item.state?(:COMMITTED) 
      posting = tote_item.posting
      travel_to posting.delivery_date + 12.hours      
      quantity = posting.total_quantity_ordered_from_creditor
      posting.fill(quantity)
    end

    travel_back

    now_count = c1.tote_items.joins(:posting).where("postings.delivery_date < ?", Time.zone.now).count

    assert_equal now_count, c1.tote_items_to_pickup.count
    assert_equal now_count, c1.tote_items_to_pickup.count

    #move 18 days out
    travel_to 18.days.from_now
    #verify items returned is zero
    assert_equal 0, c1.tote_items_to_pickup.count
    #return to normal time
    travel_back
    #verify items get returned
    assert_equal now_count, c1.tote_items_to_pickup.count
    #add a pickup object to database
    c1.pickups.create
    #move 1 day ahead
    travel_to 1.day.from_now
    #verify items returned is zero
    if c1.tote_items_to_pickup.count > 0
      c1.pickups.create      
      travel_to 61.minutes.from_now
    end

    assert_equal 0, c1.tote_items_to_pickup.count
    
    travel_back
   
  end

  test "should change dropsites" do
    assert @user.valid?
    assert_nil @user.dropsite
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    dropsite_id = @user.dropsite.id
    new_dropsite = dropsites(:dropsite2)    
    @user.set_dropsite(new_dropsite)
    @user.reload
    assert_not dropsite_id == @user.dropsite.id
  end

  test "should change pickup code when switching dropsites" do
    assert @user.valid?
    assert_nil @user.dropsite
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    old_code = @user.pickup_code.code
    dropsite_id = @user.dropsite.id
    new_dropsite = dropsites(:dropsite2)    
    @user.set_dropsite(new_dropsite)
    @user.reload
    assert_not dropsite_id == @user.dropsite.id
    new_code = @user.pickup_code.code
    assert new_code != old_code
  end

  test "should not change dropsite if dropsite is invalid" do

    assert @user.valid?
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    dropsite_id = @user.dropsite.id
    @user.set_dropsite(nil)
    assert @user.valid?
    assert_equal dropsite_id, @user.dropsite.id

    @user.set_dropsite("david")
    assert @user.valid?
    assert_equal dropsite_id, @user.dropsite.id

    invalid_dropsite = Dropsite.new(name: nil, hours: "7-7", address: "1234 main", city: "Kirkland", state: "WA", zip: 98033)
    invalid_dropsite.save
    assert_not invalid_dropsite.valid?

    @user.set_dropsite(invalid_dropsite)
    assert_equal dropsite_id, @user.dropsite.id

  end

  test "should be invalid account type" do
    @user.account_type = nil
    assert_not @user.valid?
  end

    test "should be invalid account type one" do
    @user.account_type = -1
    assert_not @user.valid?
  end

  test "should be invalid account type two" do
    @user.account_type = -3
    assert_not @user.valid?
  end

  test "should be valid account type" do
    @user.account_type = 1
    assert_not @user.valid?
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "     "
    #commenting this out because name not necessary at Farmer's Cellar
    #assert_not @user.valid?
  end

  test "email should be present" do
  	@user.email = "    "
  	assert_not @user.valid?
  end

  test "name shouldn't be too long" do
  	@user.name = "a" * 51
  	assert_not @user.valid?
  end

  test "email shouldn't be too long" do
  	@user.email = "a" * 244 + "@example.com"
  	assert_not @user.valid?
  end

  test "email validation should accept valid email addresses" do
  	valid_addresses = %w[user@example.com USER@foo.com A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
  	valid_addresses.each do |valid_address|
  		@user.email = valid_address
  		assert @user.valid?, "#{valid_address.inspect} should be valid"
  	end
  end

  test "email validation should reject invalid addresses" do
  	invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.foo@bar_baz.com foo@bar+baz.com]
  	invalid_addresses.each do |invalid_address|
  		@user.email = invalid_address
  		assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
  	end
  end

  test "email addresses should be unique" do
  	duplicate_user = @user.dup
  	duplicate_user.email = @user.email.upcase
  	@user.save
  	assert_not duplicate_user.valid?
  end

  test "password should be above minimum length" do
  	@user.password = @user.password_confirmation = "a" * 5
  	assert_not @user.valid?
  end
end
