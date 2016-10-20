require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar", zip: 98033, account_type: 0)
    @f6 = users(:f6)
    @f7 = users(:f7)
    @f8 = users(:f8)
    @d1 = users(:d1)
  end

  #what if you have a producer that has no distributor. can you call producer.get_postings_orderable(postings_at_order_cutoff) on it and have it do the right thing?
  test "should return proper orderable report when distributor postings reporter called on a producer with no distributor" do

    nuke_all_postings

    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
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
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)
    sam = create_user("sam", "sam@s.com", 98055)

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 6, bob)
    ti_bob_carrots.update(state: ToteItem.states[:COMMITTED])
    ti_chris_carrots = create_tote_item(posting_carrots, quantity = 12, chris)
    ti_chris_carrots.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])

    report = producer1.get_postings_orderable([posting_carrots])
    producer1_net_value = 49.32
    assert_equal producer1_net_value, report[:postings_total_producer_net]

  end

  test "should find orderable postings when distributor has lots of postings with various order cutoffs with case and order minimums are met" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com", "WA", 98033, "www.oxbow.com", "OXBOW FARMS")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
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
    czs1 = posting_celery.commitment_zone_start

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.commitment_zone_start
    
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
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)
    sam = create_user("sam", "sam@s.com", 98055)

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_sam_celery = create_tote_item(posting_celery, quantity = 2, sam)
    ti_sam_celery.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 6, bob)
    ti_bob_carrots.update(state: ToteItem.states[:COMMITTED])
    ti_chris_carrots = create_tote_item(posting_carrots, quantity = 12, chris)
    ti_chris_carrots.update(state: ToteItem.states[:COMMITTED])

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 12, num_cases: 1, contribution: $50
    ti_sam_beef = create_tote_item(posting_beef, quantity = 6, sam)
    ti_sam_beef.update(state: ToteItem.states[:COMMITTED])
    ti_chris_beef = create_tote_item(posting_beef, quantity = 6, chris)
    ti_chris_beef.update(state: ToteItem.states[:COMMITTED])

    #-----------------------------------------------------------------------------------------------

    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(posting_apples, quantity = 3, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])
    ti_sam_apples = create_tote_item(posting_apples, quantity = 2, sam)
    ti_sam_apples.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])    

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])

    #get producer net by first commitment zone
    first_czs_oxbow_net = oxbow.get_producer_net(czs1)
    #get producer net by postings
    first_postings_distributor_net = oxbow.get_producer_net(czs1, delivery_date1_postings)
    #verify producer nets match
    assert_equal first_czs_oxbow_net, first_postings_distributor_net    
    #verify correct oxbow producer net value
    assert_equal 99.57, first_czs_oxbow_net
    #verify correct producer1 producer net value
    producer1_net_value = 49.32
    assert_equal producer1_net_value, producer1.get_producer_net(czs1)
    #verify correct producer2 producer net value
    producer2_net_value = 45.70
    assert_equal producer2_net_value, producer2.get_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, postings_total_producer_net: 0}

    report = oxbow.get_postings_orderable(delivery_date1_postings)
    assert_equal first_czs_oxbow_net, report[:postings_total_producer_net]

    report = producer1.get_postings_orderable([posting_carrots])
    assert_equal producer1_net_value, report[:postings_total_producer_net]

    report = producer2.get_postings_orderable([posting_beef])
    assert_equal producer2_net_value, report[:postings_total_producer_net]

  end

  test "should find orderable postings when distributor has lots of postings with various order cutoffs and minimums are met" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com", "WA", 98033, "www.oxbow.com", "OXBOW FARMS")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
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
    czs1 = posting_celery.commitment_zone_start

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.commitment_zone_start
    
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
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)
    sam = create_user("sam", "sam@s.com", 98055)

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_sam_celery = create_tote_item(posting_celery, quantity = 2, sam)
    ti_sam_celery.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 1, price 3.00, order min: $20, contribution: $54
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 6, bob)
    ti_bob_carrots.update(state: ToteItem.states[:COMMITTED])
    ti_chris_carrots = create_tote_item(posting_carrots, quantity = 12, chris)
    ti_chris_carrots.update(state: ToteItem.states[:COMMITTED])

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 6, contribution: $0
    ti_sam_beef = create_tote_item(posting_beef, quantity = 3, sam)
    ti_sam_beef.update(state: ToteItem.states[:COMMITTED])
    ti_chris_beef = create_tote_item(posting_beef, quantity = 3, chris)
    ti_chris_beef.update(state: ToteItem.states[:COMMITTED])

    #-----------------------------------------------------------------------------------------------

    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(posting_apples, quantity = 3, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])
    ti_sam_apples = create_tote_item(posting_apples, quantity = 2, sam)
    ti_sam_apples.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])    

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])

    #get producer net by first commitment zone
    first_czs_oxbow_net = oxbow.get_producer_net(czs1)
    #get producer net by postings
    first_postings_distributor_net = oxbow.get_producer_net(czs1, delivery_date1_postings)
    #verify producer nets match
    assert_equal first_czs_oxbow_net, first_postings_distributor_net    
    #verify correct oxbow producer net value
    assert_equal 53.87, first_czs_oxbow_net
    #verify correct producer1 producer net value
    producer1_net_value = 49.32
    assert_equal producer1_net_value, producer1.get_producer_net(czs1)
    #verify correct producer2 producer net value
    assert_equal 0, producer2.get_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, postings_total_producer_net: 0}

    report = oxbow.get_postings_orderable(delivery_date1_postings)
    assert_equal first_czs_oxbow_net, report[:postings_total_producer_net]

    report = producer1.get_postings_orderable([posting_carrots])
    assert_equal producer1_net_value, report[:postings_total_producer_net]

    report = producer2.get_postings_orderable([posting_beef])
    assert_equal 0, report[:postings_total_producer_net]

  end

  test "should return proper producer net value for postings when distributor has lots of postings with various order cutoffs" do

    nuke_all_postings

    #producing distributor
    oxbow = create_producer("oxbow", "oxbow@o.com", "WA", 98033, "www.oxbow.com", "OXBOW FARMS")
    oxbow.update(order_minimum_producer_net: 50)
    #has many producers
    producer1 = create_producer("producer1", "producer1@o.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = oxbow    
    producer1.save
    producer1.update(order_minimum_producer_net: 20)

    producer2 = create_producer("producer2", "producer2@o.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
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
    czs1 = posting_celery.commitment_zone_start

    price_apples = 2.00
    posting_apples = create_posting(oxbow, price_apples, product = products(:apples), unit = units(:pound), delivery_date2)
    delivery_date2_postings << posting_apples
    czs2 = posting_apples.commitment_zone_start
    
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
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)
    sam = create_user("sam", "sam@s.com", 98055)

    #tote items oxbow 1, price 1.00, contribution = $5.00
    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_sam_celery = create_tote_item(posting_celery, quantity = 2, sam)
    ti_sam_celery.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 1, price 3.00, order min: $20, contribution: $15
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 3, bob)
    ti_bob_carrots.update(state: ToteItem.states[:COMMITTED])
    ti_chris_carrots = create_tote_item(posting_carrots, quantity = 2, chris)
    ti_chris_carrots.update(state: ToteItem.states[:COMMITTED])

    #tote items producer2 1, price 5.00, units_per_case: 10, num_units: 6, contribution: $0
    ti_sam_beef = create_tote_item(posting_beef, quantity = 3, sam)
    ti_sam_beef.update(state: ToteItem.states[:COMMITTED])
    ti_chris_beef = create_tote_item(posting_beef, quantity = 3, chris)
    ti_chris_beef.update(state: ToteItem.states[:COMMITTED])

    #-----------------------------------------------------------------------------------------------

    #tote items oxbow 2, price 2.00, contribution = $10
    ti_bob_apples = create_tote_item(posting_apples, quantity = 3, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])
    ti_sam_apples = create_tote_item(posting_apples, quantity = 2, sam)
    ti_sam_apples.update(state: ToteItem.states[:COMMITTED])

    #tote items producer1 2, price 4.00, order min: $20, contribution: $24
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])    

    #tote items producer2 2, price 6.00, contribution: $36
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])
    ti_chris_milk = create_tote_item(posting_milk, quantity = 3, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])

    #get producer net by first commitment zone
    first_czs_oxbow_net = oxbow.get_producer_net(czs1)
    #get producer net by postings
    first_postings_distributor_net = oxbow.get_producer_net(czs1, delivery_date1_postings)
    #verify producer nets match
    assert_equal first_czs_oxbow_net, first_postings_distributor_net    
    #verify correct oxbow producer net value
    assert_equal 18.25, first_czs_oxbow_net
    #verify correct producer1 producer net value
    assert_equal 13.70, producer1.get_producer_net(czs1)
    #verify correct producer2 producer net value
    assert_equal 0, producer2.get_producer_net(czs1)

    #verify values if we call the 'orderable' methods
    #{postings_to_order: [], postings_to_close: postings_all, postings_total_producer_net: 0}
    report = oxbow.get_postings_orderable(delivery_date1_postings)
    assert_equal 0, report[:postings_total_producer_net]

    report = producer1.get_postings_orderable([posting_carrots])
    assert_equal 0, report[:postings_total_producer_net]

    report = producer2.get_postings_orderable([posting_beef])
    assert_equal 0, report[:postings_total_producer_net]

  end

  test "should return proper value for orderable postings when producer has lots of postings with various order cutoffs" do

    producer = create_producer("producer", "producer@p.com", "WA", 98033, "www.producer.com", "PRODUCER FARMS")

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    price_milk = 1.00
    posting_milk = create_posting(producer, price_milk, product = products(:milk))
    #change this order cutoff time so that it's not included in the order value computation
    posting_milk.update(commitment_zone_start: posting_milk.commitment_zone_start - 1)
    
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)
    sam = create_user("sam", "sam@s.com", 98055)

    #create tote items for all postings
    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])
    ti_sam_celery = create_tote_item(posting_celery, quantity = 9, sam)
    ti_sam_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])
    ti_sam_apples = create_tote_item(posting_apples, quantity = 6, sam)
    ti_sam_apples.update(state: ToteItem.states[:COMMITTED])

    ti_bob_milk = create_tote_item(posting_milk, quantity = 1, bob)
    ti_bob_milk.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_milk = create_tote_item(posting_milk, quantity = 2, chris)
    ti_chris_milk.update(state: ToteItem.states[:COMMITTED])
    ti_sam_milk = create_tote_item(posting_milk, quantity = 3, sam)
    ti_sam_milk.update(state: ToteItem.states[:COMMITTED])

    expected_celery_posting_value = 41.04
    expected_apples_posting_value = 21.96
    expected_order_value = expected_celery_posting_value + expected_apples_posting_value
    assert_equal 63, expected_order_value

    assert_equal expected_celery_posting_value, posting_celery.inbound_order_value_producer_net
    assert_equal expected_apples_posting_value, posting_apples.inbound_order_value_producer_net

    czs = posting_celery.commitment_zone_start
    producer_net = producer.get_producer_net(czs)

    assert_equal expected_order_value, producer_net

  end

  test "should submit orders when producer has no order minimum" do

    producer = create_producer("producer", "producer@p.com", "WA", 98033, "www.producer.com", "PRODUCER FARMS")

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal report[:postings_to_order].first, posting_celery
    assert_equal report[:postings_to_order].last, posting_apples
    assert_equal 0, report[:postings_to_close].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:postings_total_producer_net]

  end

  test "should submit orders when total producer net meets producer order minimum" do
    producer = create_producer("producer", "producer@p.com", "WA", 98033, "www.producer.com", "PRODUCER FARMS")

    order_minimum = 30
    producer.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, producer.reload.order_minimum_producer_net

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal report[:postings_to_order].first, posting_celery
    assert_equal report[:postings_to_order].last, posting_apples
    assert_equal 0, report[:postings_to_close].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:postings_total_producer_net]
  end

  test "should not submit orders when total producer net is below producer order minimum" do
    producer = create_producer("producer", "producer@p.com", "WA", 98033, "www.producer.com", "PRODUCER FARMS")

    order_minimum = 32
    producer.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, producer.reload.order_minimum_producer_net

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = producer.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal 0, report[:postings_to_order].count
    assert_equal report[:postings_to_close].first, posting_celery
    assert_equal report[:postings_to_close].last, posting_apples
    #verify total order amount    
    assert_equal 0, report[:postings_total_producer_net]
  end

  test "should submit orders when distributor has no order minimum" do
    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "BIGTIME DISTRIBUTOR GUY")
    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal report[:postings_to_order].first, posting_celery
    assert_equal report[:postings_to_order].last, posting_apples
    assert_equal 0, report[:postings_to_close].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:postings_total_producer_net]
  end

  test "should submit orders when producer orders meet distributor order minimum" do
    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "BIGTIME DISTRIBUTOR GUY")
    order_minimum = 30
    distributor.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, distributor.reload.order_minimum_producer_net
    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal report[:postings_to_order].first, posting_celery
    assert_equal report[:postings_to_order].last, posting_apples
    assert_equal 0, report[:postings_to_close].count
    #verify total order amount    
    assert_equal expected_producer_net, report[:postings_total_producer_net]
  end
  
  test "should not submit orders when producer orders do not meet distributor order minimum" do
    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "BIGTIME DISTRIBUTOR GUY")
    order_minimum = 32
    distributor.update(order_minimum_producer_net: order_minimum)
    assert_equal order_minimum, distributor.reload.order_minimum_producer_net
    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal 0, report[:postings_to_order].count

    assert_equal report[:postings_to_close].first, posting_celery
    assert_equal report[:postings_to_close].last, posting_apples    
    #verify total order amount    
    assert_equal 0, report[:postings_total_producer_net]
  end

  test "should exclude producer from distributor order submission when producer order minimum is not met" do
    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "BIGTIME DISTRIBUTOR GUY")
    distributor_order_minimum = 10
    distributor.update(order_minimum_producer_net: distributor_order_minimum)
    assert_equal distributor_order_minimum, distributor.reload.order_minimum_producer_net

    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = distributor
    producer1.save
    producer1_order_minimum = 25
    producer1.update(order_minimum_producer_net: producer1_order_minimum)
    assert_equal producer1_order_minimum, producer1.reload.order_minimum_producer_net

    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
    producer2.distributor = distributor
    producer2.save

    #create postings
    price_celery = 2.50
    posting_celery = create_posting(producer1, price_celery, product = products(:celery))

    price_apples = 2.00
    posting_apples = create_posting(producer2, price_apples, product = products(:apples))    

    #create tote items
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net
    expected_producer_net = 31.50
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.get_postings_orderable([posting_celery, posting_apples])
    #verify all postings returned
    assert_equal 1, report[:postings_to_order].count
    assert_equal posting_apples, report[:postings_to_order].last

    assert_equal 1, report[:postings_to_close].count
    assert_equal posting_celery, report[:postings_to_close].last

    #verify total order amount    
    assert_equal expected_producer_net_apples, report[:postings_total_producer_net]
  end

  test "should submit orders properly when distributor is itself a producer" do
    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "BIGTIME DISTRIBUTOR GUY")
    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 FARMS")
    producer1.distributor = distributor
    producer1.save
    producer2 = create_producer("producer2", "producer2@p.com", "WA", 98033, "www.producer2.com", "producer2 FARMS")
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
    bob = create_user("bob", "bob@b.com", 98033)
    chris = create_user("chris", "chris@c.com", 98044)

    ti_bob_milk = create_tote_item(posting_milk, quantity = 1, bob)
    ti_bob_milk.update(state: ToteItem.states[:COMMITTED])

    ti_bob_celery = create_tote_item(posting_celery, quantity = 3, bob)
    ti_bob_celery.update(state: ToteItem.states[:COMMITTED])
    ti_chris_celery = create_tote_item(posting_celery, quantity = 6, chris)
    ti_chris_celery.update(state: ToteItem.states[:COMMITTED])

    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.update(state: ToteItem.states[:COMMITTED])    
    ti_chris_apples = create_tote_item(posting_apples, quantity = 4, chris)
    ti_chris_apples.update(state: ToteItem.states[:COMMITTED])

    #verify inbound_order_value_producer_net value
    gross_milk = price_milk
    commission_per_unit_milk = 0.50
    payment_processor_fee_unit_milk = 0.35
    producer_net_unit_milk = (price_milk - commission_per_unit_milk - payment_processor_fee_unit_milk).round(2)
    assert_equal 9.15, producer_net_unit_milk
    assert_equal producer_net_unit_milk, posting_milk.get_producer_net_unit
    expected_producer_net_milk = 9.15
    assert_equal expected_producer_net_milk, posting_milk.inbound_order_value_producer_net    

    gross_celery = 22.50
    commission_per_unit_celery = 0.13
    payment_processor_fee_unit_celery = 0.09
    producer_net_unit_celery = (price_celery - commission_per_unit_celery - payment_processor_fee_unit_celery).round(2)
    assert_equal 2.28, producer_net_unit_celery
    assert_equal producer_net_unit_celery, posting_celery.get_producer_net_unit
    expected_producer_net_celery = 20.52
    assert_equal expected_producer_net_celery, posting_celery.inbound_order_value_producer_net

    gross_apples = 12
    commission_per_unit_apples = 0.10
    payment_processor_fee_unit_apples = 0.07
    producer_net_unit_apples = (price_apples - commission_per_unit_apples - payment_processor_fee_unit_apples).round(2)
    assert_equal 1.83, producer_net_unit_apples
    assert_equal producer_net_unit_apples, posting_apples.get_producer_net_unit
    expected_producer_net_apples = 10.98
    assert_equal expected_producer_net_apples, posting_apples.inbound_order_value_producer_net

    producer_net = posting_apples.inbound_order_value_producer_net + posting_celery.inbound_order_value_producer_net + posting_milk.inbound_order_value_producer_net
    expected_producer_net = 40.65
    assert_equal expected_producer_net, producer_net

    #get_postings_orderable(postings_presently_transitioning_to_commitment_zone) should return postings
    report = distributor.get_postings_orderable([posting_celery, posting_apples, posting_milk])
    #verify all postings returned
    assert_equal 0, report[:postings_to_close].count
    assert_equal 3, report[:postings_to_order].count
    assert_equal posting_celery.product.name, report[:postings_to_order].first.product.name
    assert_equal posting_apples.product.name, report[:postings_to_order].second.product.name
    assert_equal posting_milk.product.name, report[:postings_to_order].last.product.name
        
    #verify total order amount    
    assert_equal expected_producer_net, report[:postings_total_producer_net]
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

  def setup_pickup_testing
    
    nuke_all_postings
    producer = create_producer("producer", "producer@o.com", "WA", 98033, "www.producer.com", "producer FARMS")
    producer.save
    delivery_date = get_delivery_date(days_from_now = 14)
    days_shift = delivery_date.wday - 3
    delivery_date = delivery_date - days_shift.days
    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date)
    bob = create_user("bob", "bob@b.com", 98033)
    bob.set_dropsite(Dropsite.first)
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 6, bob)
    ti_bob_carrots.transition(:customer_authorized)
    ti_bob_carrots.transition(:commitment_zone_started)          
    ti_bob_carrots.transition(:tote_item_filled, {quantity_filled: ti_bob_carrots.quantity})      

    return bob

  end

  test "second pickup of the week should not display items picked up during first pickup" do

    nuke_all_postings
    producer = create_producer("producer", "producer@o.com", "WA", 98033, "www.producer.com", "producer FARMS")
    producer.save
    delivery_date = get_delivery_date(days_from_now = 14)    
    days_shift = delivery_date.wday - 3
    delivery_date = delivery_date - days_shift.days
    delivery_date2 = delivery_date + 2.days

    posting_carrots = create_posting(producer, price = 1.50, product = products(:carrots), unit = units(:pound), delivery_date)
    bob = create_user("bob", "bob@b.com", 98033)
    bob.set_dropsite(Dropsite.first)
    ti_bob_carrots = create_tote_item(posting_carrots, quantity = 6, bob)
    ti_bob_carrots.transition(:customer_authorized)
    ti_bob_carrots.transition(:commitment_zone_started)          
    ti_bob_carrots.transition(:tote_item_filled, {quantity_filled: ti_bob_carrots.quantity})      

    posting_apples = create_posting(producer, price = 2.50, product = products(:apples), unit = units(:pound), delivery_date2)
    ti_bob_apples = create_tote_item(posting_apples, quantity = 2, bob)
    ti_bob_apples.transition(:customer_authorized)
    ti_bob_apples.transition(:commitment_zone_started)          
    ti_bob_apples.transition(:tote_item_filled, {quantity_filled: ti_bob_apples.quantity})

    #do a pickup now
    bob.pickups.create
    #verify there's 1 pickup
    assert_equal 1, bob.pickups.count
    #travel between delivery dates
    travel_to delivery_date + 1.day
    #verify carrots are available for pickup
    assert_equal 1, bob.tote_items_to_pickup.count
    assert_equal "Carrots", bob.tote_items_to_pickup.first.posting.product.name    
    #pick up carrots
    bob.pickups.create
    #verify there's 2 pickups
    assert_equal 2, bob.pickups.count
    #travel 61 minutes forward
    travel_to Time.zone.now + 61.minutes
    #verify nothing is available for pickup
    assert_equal 0, bob.tote_items_to_pickup.count
    #travel a day after apples delivery
    travel_to delivery_date2 + 1.day
    #verify apples are available for pickup
    assert_equal 1, bob.tote_items_to_pickup.count
    assert_equal "Fuji Apples", bob.tote_items_to_pickup.first.posting.product.name
    #pickup apples
    bob.pickups.create
    #verify there's 3 pickups
    assert_equal 3, bob.pickups.count
    #travel 61 minutes forward
    travel_to Time.zone.now + 61.minutes
    #verify nothing is available for pickup
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back

  end

  test "items delivered on wednesday should be available for pickup on thursday" do    

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    travel_to Time.zone.now + 61.minutes
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back

  end

  test "items delivered on wednesday should not be available for pickup next tuesday" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    travel_to bob.tote_items.first.posting.delivery_date + 6.days    
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back    

  end

  test "items picked up 30 minutes ago should still be available for pickup" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    assert_equal 2, bob.pickups.count
    travel_to Time.zone.now + 30.minutes
    assert_equal 1, bob.tote_items_to_pickup.count

    travel_back

  end

  test "items picked up 90 minutes ago should not still be available for pickup" do

    bob = setup_pickup_testing

    assert_equal 0, bob.pickups.count
    bob.pickups.create
    assert_equal 1, bob.pickups.count

    travel_to bob.tote_items.first.posting.delivery_date + 1.day
    assert_equal 1, bob.tote_items_to_pickup.count
    bob.pickups.create
    assert_equal 2, bob.pickups.count
    travel_to Time.zone.now + 90.minutes
    assert_equal 0, bob.tote_items_to_pickup.count

    travel_back

  end

  test "should get tote items to pickup" do

    c1 = users(:c1)

    c1.tote_items.each do |tote_item|            
      tote_item.update(state: ToteItem.states[:ADDED])
      tote_item.transition(:customer_authorized)
      tote_item.transition(:commitment_zone_started)          
      tote_item.transition(:tote_item_filled, {quantity_filled: tote_item.quantity})      
    end

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
    assert_equal nil, @user.dropsite
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
    assert_equal nil, @user.dropsite
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
