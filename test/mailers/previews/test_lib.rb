module TestLib

  def create_food_category(name, parent)

    fc = FoodCategory.new(name: name, parent: parent)
    assert fc.save

    return fc

  end

  def create_creditor_order(creditor = nil, postings = nil, customer = nil)

    if creditor.nil?      
      creditor = create_producer
    end

    if postings.nil?
      postings = [create_posting(creditor)]
    end

    if customer.nil?
      customer = create_user
    end

    postings.each do |posting|
      create_tote_item(customer, posting, 2)
    end
    
    create_one_time_authorization_for_customer(customer)
    corder = CreditorOrder.submit(postings)
    assert corder.valid?

    return corder

  end

  def do_hourly_tasks_at(date_time)
    travel_to date_time
    RakeHelper.do_hourly_tasks
  end

  def transition_to_authorized(tote_item)

    assert tote_item
    assert tote_item.state?(:ADDED)

    tote_item.transition(:customer_authorized)

    assert tote_item.reload.state?(:AUTHORIZED)

  end

  def clear_mailer
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  def create_db_objects
    #creates a distributor with OM $100 that gets met
    #distributor has 3 postings
    #distributor has 3 producers
    #each producer has 3 postings
    #producer 1 has OM $50 that gets met
    #producer 1 has a Product5 posting with OM $20 that does not get met
    #producer 2 has OM $50 that does not get met
    
    bob = create_user("bob", "bob@b.com")

    delivery_date = get_delivery_date(10)

    order_cutoff1 = delivery_date - 4.days
    order_cutoff2 = delivery_date - 3.days
    order_cutoff3 = delivery_date - 2.days

    order_cutoffs = [order_cutoff1, order_cutoff2, order_cutoff3]    

    tis = []
    postings = []
    #create distributor D1
    distributor = create_distributor("distributor", "distributor@d.com", 100)
    posting1 = create_posting(distributor, price = 10, get_product("Product1"), get_unit("Pound"), delivery_date, order_cutoff1, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)    
    tis << create_tote_item(bob, posting1, 1)
    posting2 = create_posting(distributor, price = 10, get_product("Product2"), get_unit("Pound"), delivery_date, order_cutoff2, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting2, 1)
    posting3 = create_posting(distributor, price = 10, get_product("Product3"), get_unit("Pound"), delivery_date, order_cutoff3, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting3, 1)

    f1 = create_producer("producer1", "producer1@p.com", distributor, order_min = 50)
    posting4 = create_posting(f1, price = 10, get_product("Product4"), get_unit("Pound"), delivery_date, order_cutoff1, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting4, 7)        
    posting5 = create_posting(f1, price = 10, get_product("Product5"), get_unit("Pound"), delivery_date, order_cutoff2, units_per_case = nil, frequency = nil, order_minimum_producer_net = 20)
    tis << create_tote_item(bob, posting5, 1)
    posting6 = create_posting(f1, price = 10, get_product("Product6"), get_unit("Pound"), delivery_date, order_cutoff3, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting6, 7)

    f2 = create_producer("producer2", "producer2@p.com", distributor, order_min = 50)
    posting7 = create_posting(f2, price = 10, get_product("Product7"), get_unit("Pound"), delivery_date, order_cutoff1, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting7, 1)
    posting8 = create_posting(f2, price = 10, get_product("Product8"), get_unit("Pound"), delivery_date, order_cutoff2, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting8, 1)
    posting9 = create_posting(f2, price = 10, get_product("Product9"), get_unit("Pound"), delivery_date, order_cutoff3, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting9, 1)

    f3 = create_producer("producer3", "producer3@p.com", distributor)
    posting10 = create_posting(f3, price = 10, get_product("Product10"), get_unit("Pound"), delivery_date, order_cutoff1, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting10, 12)
    posting11 = create_posting(f3, price = 10, get_product("Product11"), get_unit("Pound"), delivery_date, order_cutoff2, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting11, 12)
    posting12 = create_posting(f3, price = 10, get_product("Product12"), get_unit("Pound"), delivery_date, order_cutoff3, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)
    tis << create_tote_item(bob, posting12, 12)

    tis.each do |ti|
      ti.transition(:customer_authorized)
      if Rails.env.test?
        assert ti.reload.state?(:AUTHORIZED)
      end
    end

    if Rails.env.test?
      assert distributor.outbound_order_value_producer_net(order_cutoff1) > 0
      assert distributor.outbound_order_value_producer_net(order_cutoff2) > 0
      assert distributor.outbound_order_value_producer_net(order_cutoff3) > 0
      
      assert f1.outbound_order_value_producer_net(order_cutoff1) > 0
      assert_equal 0, posting5.outbound_order_value_producer_net
      assert_equal 0, f1.outbound_order_value_producer_net(order_cutoff2)
      assert f1.outbound_order_value_producer_net(order_cutoff3) > 0

      assert_equal 0, f2.outbound_order_value_producer_net(order_cutoff1)
      assert_equal 0, f2.outbound_order_value_producer_net(order_cutoff2)
      assert_equal 0, f2.outbound_order_value_producer_net(order_cutoff3)
    end

    postings = [posting1, posting2, posting3, posting4, posting5, posting6, posting7, posting8, posting9, posting10, posting11, posting12]

    return {customer: bob, delivery_date: delivery_date, order_cutoffs: order_cutoffs, distributor: distributor, producers: [f1, f2, f3], postings: postings, tote_items: tis}

  end

  def destroy_objects(objects)

    if objects && objects.any?
      objects.each do |obj|
        obj.destroy
      end
    end

  end

  def get_product(name = "Fuji Apples")

    product = Product.find_by(name: name)

    if product
      return product
    end

    return Product.create(name: name)

  end

  def get_unit(name = "Pound")

    unit = Unit.find_by(name: name)

    if unit
      return unit
    end

    return Unit.create(name: name)

  end

  def create_commission(farmer, product, unit, commission)    
    
    ppuc = ProducerProductUnitCommission.new(user: farmer, product: product, unit: unit, commission: commission)

    if Rails.env.test?
      assert ppuc.valid?
      assert ppuc.save
    else
      ppuc.save
    end

    return ppuc

  end

  def create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0)

    if order_cutoff && delivery_date
      assert order_cutoff < delivery_date
    end

    if farmer.nil?
      farmer = create_producer("john", "john@j.com")
      assert farmer.valid?
      assert farmer.producer?
    end

    if price.nil?
      price = 1.0
    end

    if product.nil?
      product = products(:apples)
    end

    if unit.nil?
      unit = units(:pound)
    end

    if delivery_date.nil?
      delivery_date = get_delivery_date(days_from_now = 7)
    end

    if order_cutoff.nil?
      order_cutoff = delivery_date - 2.days
    end

    if units_per_case.nil?
      units_per_case = 1
    end

    if frequency.nil?
      frequency = 0
    end

    if !ProducerProductUnitCommission.where(user: farmer, product: product, unit: unit).any?
      create_commission(farmer, product, unit, 0.05)
    end

    posting = Posting.create(
      live: true,
      delivery_date: delivery_date,
      order_cutoff: order_cutoff,
      product_id: product.id,
      price: price,
      user_id: farmer.id,
      unit_id: unit.id,
      description: "this is a description of the posting",
      order_minimum_producer_net: order_minimum_producer_net
      )

    assert posting.save

    if Rails.env.test?
      assert posting.valid?
    end    

    if frequency && frequency > 0
      posting_recurrence = PostingRecurrence.new(frequency: frequency, on: true)
      posting_recurrence.postings << posting
      assert posting_recurrence.save
    end

    return posting

  end

  def create_tote_item(customer, posting, quantity)

    tote_item = ToteItem.create(user: customer, posting: posting, quantity: quantity, price: posting.price, state: ToteItem.states[:ADDED])
    assert tote_item.valid?

    return tote_item

  end

  def create_one_time_authorization_for_customer(customer)

    assert customer

    customer.tote_items.each do |tote_item|
      tote_item.transition(:customer_authorized)
      tote_item.reload
      assert tote_item.state?(:AUTHORIZED)
    end

  end

  def create_subscription(user, posting, quantity, frequency)

    assert user.valid?
    assert posting.valid?
    assert posting.posting_recurrence

    tote_item = create_tote_item(posting, quantity, user)
    subscription = Subscription.new(kind: Subscription.kinds[:NORMAL], frequency: frequency, on: true, user: user, posting_recurrence: posting.posting_recurrence, quantity: quantity, paused: false)

    if frequency == 0
      subscription.kind = Subscription.kinds[:ROLLUNTILFILLED]
    end

    assert subscription.save    
    subscription.tote_items << tote_item
    subscription.save

    return subscription

  end

  def get_admin

    admin = User.where(account_type: User.types[:ADMIN]).first

    if admin
      return admin
    end

    return create_admin

  end

  def create_admin(name = "Mr. Admin", email = "admin@a.com")
    
    admin = create_user(name, email)
    assert admin.valid?
    admin.update(account_type: User.types[:ADMIN])
    assert admin.reload.account_type_is?(:ADMIN)

    return admin

  end

  def create_user(name = "customer name", email = "customer@c.com")

    user = User.find_by(email: email)

    if user
      user.destroy
    end

    user = User.create!(
      name:  name,
      email: email,
      password: "dogdog",
      password_confirmation: "dogdog",
      account_type: '0',
      activated: true,
      activated_at: Time.zone.now,
      address: "4215 21st St. SW",
      city: "Redmond",
      state: "Washington",
      zip: "98008",
      phone: "206-599-6579",
      beta: false
      )

    if Rails.env.test?
      assert user.valid?
    end

    return user

  end

  def create_producer(name = "producer name", email = "producer@p.com", distributor = nil, order_min = 0)
    
    user = create_user(name, email)    
    user.update(
      account_type: User.types[:PRODUCER],
      distributor: distributor,
      order_minimum_producer_net: order_min,
      description: "description of #{name} farm",
      website: "www.#{name}.com",
      farm_name: "#{name} Farms")

    producer = user.reload
    create_business_interface(producer)

    return producer

  end

  def create_distributor(name = "distributor name", email = "distributor@d.com", order_min = 0)
    return create_producer(name, email, distributor = nil, order_min)
  end

  def create_creditor_with(payment_method_key, payment_time_key, creditor = nil)

    if creditor.nil?
      creditor = create_producer(name = "producer name", email = "producer@p.com")
    end
    bi = creditor.get_creditor.get_business_interface
    bi.update(payment_method: BusinessInterface.payment_methods[payment_method_key], payment_time: BusinessInterface.payment_times[payment_time_key])

    return creditor.reload

  end

  def create_business_interface(creditor, order_instructions = "order instructions", payment_method = BusinessInterface.payment_methods[:PAYPAL], payment_instructions = "payment instructions", payment_time = BusinessInterface.payment_times[:AFTERDELIVERY])

    creditor.create_business_interface(
      name: "#{creditor.name} #{creditor.name}, Inc.",
      order_email: creditor.email,
      order_instructions: order_instructions,
      payment_method: payment_method,
      paypal_email: creditor.email,
      payment_instructions: payment_instructions,
      payment_time: payment_time
      )

  end

  #days_from_now can be any integer, positive, zero or negative
  def get_delivery_date(days_from_now)

    today = Time.zone.now.midnight
    delivery_date = today + days_from_now.days

    if delivery_date.sunday?
      delivery_date += 1.day
    end

    return delivery_date

  end

  def nuke_all_tote_items
    ToteItem.delete_all
    assert_equal 0, ToteItem.count
  end

  def nuke_all_users
    User.delete_all
    assert_equal 0, User.count
  end

  def nuke_all_postings
    Posting.delete_all
    assert_equal 0, Posting.count
  end

end