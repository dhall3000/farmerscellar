module TestLib

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

  def create_posting(producer, price, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, commission = nil, order_minimum_producer_net = nil)

    if delivery_date.nil?
      delivery_date = get_delivery_date(days_from_now = 7)
    end

    if commitment_zone_start.nil?
      commitment_zone_start = delivery_date - 2.days
    end

    if Rails.env.test?

      if product.nil?
        product = products(:apples)
      end

      if unit.nil?
        unit = units(:pound)
      end

    end

    if commission.nil?
      commission = 0.05
    end

    create_commission(producer, product, unit, commission)

    if order_minimum_producer_net

      posting = Posting.create(
        live: true,
        delivery_date: delivery_date,
        commitment_zone_start: commitment_zone_start,
        product_id: product.id,
        quantity_available: 100,
        price: price,
        user_id: producer.id,
        unit_id: unit.id,
        description: "this is a description of the posting",
        order_minimum_producer_net: order_minimum_producer_net
        )

    else

      posting = Posting.create(
        live: true,
        delivery_date: delivery_date,
        commitment_zone_start: commitment_zone_start,
        product_id: product.id,
        quantity_available: 100,
        price: price,
        user_id: producer.id,
        unit_id: unit.id,
        description: "this is a description of the posting"
        )

    end

    if Rails.env.test?
      assert posting.valid?
    end

    return posting

  end

  def create_posting_recurrence(posting_recurrence_frequency = nil, order_cutoff = nil, delivery_date = nil)

    posting = create_posting(create_producer("john", "john@j.com"), 1.25)
    posting_recurrence = PostingRecurrence.new(frequency: posting_recurrence_frequency, on: true)
    posting_recurrence.postings << posting
    assert posting_recurrence.save

    if order_cutoff && delivery_date
      assert order_cutoff < delivery_date
      posting.update(commitment_zone_start: order_cutoff, delivery_date: delivery_date)
      assert posting.valid?
    end

    return posting_recurrence

  end

  def create_tote_item(posting, quantity, user)

    tote_item = ToteItem.create(user: user, posting: posting, quantity: quantity, price: posting.price, state: ToteItem.states[:ADDED])
    assert tote_item.valid?

    return tote_item

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

    producer.settings.update(conditional_payment: true)
    create_business_interface(producer)

    return producer

  end

  def create_distributor(name = "distributor name", email = "distributor@d.com", order_min = 0)
    return create_producer(name, email, distributor = nil, order_min)
  end

  def create_business_interface(creditor, order_email_accepted = true, order_instructions = "order instructions", paypal_accepted = true, payment_instructions = "payment instructions")

    creditor.create_business_interface(
      name: "#{creditor.name} #{creditor.name}, Inc.",
      order_email_accepted: order_email_accepted,
      order_email: creditor.email,
      order_instructions: order_instructions,
      paypal_accepted: paypal_accepted,
      paypal_email: creditor.email,
      payment_instructions: payment_instructions
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

end