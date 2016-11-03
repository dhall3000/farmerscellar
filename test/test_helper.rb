ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def do_posting_spacing(posting_recurrence)

    postings = posting_recurrence.postings
    assert postings.count > 1, "there aren't enough postings in this recurrence to test the spacing"

    seconds_per_hour = 60 * 60
    num_seconds_per_day = seconds_per_hour * 24
    num_seconds_per_week = 7 * num_seconds_per_day

    #these are for measuring gaps in monthly subscriptions. the lowest number of days from one delivery to the next
    #is 28. but the highest is 31 + 6 (which is the same as 28 + 9). The "+ 6" is because say we're delivering
    #on "first friday of the month" and that the last day of the month is Friday. in this case the next friday
    #which would be the 1st friday of the next month, is the 6th day of the month
    num_seconds_per_month_lo = num_seconds_per_week * 4
    num_seconds_per_month_hi = num_seconds_per_month_lo + (9 * num_seconds_per_day)

    if posting_recurrence.frequency > 0 && posting_recurrence.frequency < 6

      count = 1
      while count < postings.count

        spacing = postings[count].delivery_date - postings[count - 1].delivery_date

        if !postings[count].delivery_date.dst? && postings[count - 1].delivery_date.dst?
          spacing -= seconds_per_hour
        end

        if postings[count].delivery_date.dst? && !postings[count - 1].delivery_date.dst?
          spacing += seconds_per_hour
        end

        if posting_recurrence.frequency == 5
          assert spacing.seconds >= num_seconds_per_month_lo.seconds
          assert spacing.seconds <= num_seconds_per_month_hi.seconds
        else
          assert_equal num_seconds_per_week * posting_recurrence.frequency, spacing
        end
        
        count += 1

      end

    else
      assert false, "posting_recurrence frequence #{posting_recurrence.frequency.to_s} not implemented"
    end

  end

  def do_tote_item_spacing(posting_recurrence)

    seconds_per_hour = 60 * 60
    num_seconds_per_day = seconds_per_hour * 24
    num_seconds_per_week = 7 * num_seconds_per_day
    #these are for measuring gaps in monthly subscriptions. the lowest number of days from one delivery to the next
    #is 28. but the highest is 31 + 6 (which is the same as 28 + 9). The "+ 6" is because say we're delivering
    #on "first friday of the month" and that the last day of the month is Friday. in this case the next friday
    #which would be the 1st friday of the next month, is the 6th day of the month
    num_seconds_per_month_lo = num_seconds_per_week * 4
    num_seconds_per_month_hi = num_seconds_per_month_lo + (9 * num_seconds_per_day)

    postings = posting_recurrence.postings
    subscription = posting_recurrence.subscriptions.last
    tote_items = subscription.tote_items

    assert postings.count > 1, "there aren't enough postings in this recurrence to test the tote items spacing"
    assert tote_items.count > 1, "there aren't enough tote_items in this subscription to test the tote items spacing"

    if posting_recurrence.frequency > 0 && posting_recurrence.frequency < 5
      count = 1
      while count < tote_items.count

        actual_spacing = tote_items[count].posting.delivery_date - tote_items[count - 1].posting.delivery_date
        expected_spacing = num_seconds_per_week * posting_recurrence.frequency * subscription.frequency

        if !tote_items[count].posting.delivery_date.dst? && tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing += seconds_per_hour
        end

        if tote_items[count].posting.delivery_date.dst? && !tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing -= seconds_per_hour
        end

        assert_equal expected_spacing, actual_spacing
        count += 1
      end
    elsif posting_recurrence.frequency == 5
      count = 1
      while count < tote_items.count

        actual_spacing = tote_items[count].posting.delivery_date - tote_items[count - 1].posting.delivery_date

        expected_spacing_lo = num_seconds_per_month_lo * subscription.frequency
        expected_spacing_hi = num_seconds_per_month_hi * subscription.frequency

        if !tote_items[count].posting.delivery_date.dst? && tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing_lo += seconds_per_hour
          expected_spacing_hi += seconds_per_hour
        end

        if tote_items[count].posting.delivery_date.dst? && !tote_items[count - 1].posting.delivery_date.dst?
          expected_spacing_lo -= seconds_per_hour
          expected_spacing_hi -= seconds_per_hour
        end

        assert actual_spacing.seconds >= expected_spacing_lo.seconds
        assert actual_spacing.seconds <= expected_spacing_hi.seconds
        
        count += 1

      end
    else
      assert false, "do_tote_item_spacing doesn't test frequency #{posting_recurrence.frequency.to_s} yet"
    end

  end

  def add_tote_item(customer, posting, quantity, frequency = nil, roll_until_filled = nil)
 
    log_in_as(customer)
    assert is_logged_in?

    post tote_items_path, params: {tote_item: {quantity: quantity, posting_id: posting.id}}
    tote_item = assigns(:tote_item)
    additional_units_required_to_fill_my_case = tote_item.additional_units_required_to_fill_my_case

    assert :redirected
    assert_response :redirect

    if !frequency
      frequency = 0
    end    

    follow_redirect!

    if  frequency == 0 && !roll_until_filled
      if posting.posting_recurrence.nil? || !posting.posting_recurrence.on
        assert_equal "Tote item added", flash[:success]
        return tote_item
      end
    end

    post subscriptions_path, params: {tote_item_id: tote_item.id, frequency: frequency, roll_until_filled: roll_until_filled}

    if roll_until_filled || frequency > 0
      subscription = assigns(:subscription)
      assert subscription.valid?
    end

    if subscription
      if roll_until_filled
        assert subscription.kind?(:ROLLUNTILFILLED)
      else
        assert subscription.kind?(:NORMAL)
      end
    end

    assert_redirected_to postings_path
    follow_redirect!

    if frequency > 0
      assert_equal "Subscription added", flash[:success]
    else  
      assert_equal "Tote item added", flash[:success]
    end    

    return tote_item

  end

  def create_rt_authorization_for_customer(customer)

    set_dropsite(customer)
    items_total_gross = get_items_total_gross(customer)

    if customer.rtbas.count == 0 || !customer.rtbas.last.ba_valid?

      checkouts_count = Checkout.count
      post checkouts_path, params: {amount: items_total_gross, use_reference_transaction: "1"}
      assert_equal nil, flash[:danger]
      assert_equal checkouts_count + 1, Checkout.count
      assert_equal true, Checkout.last.is_rt
      checkout = assigns(:checkout)
      follow_redirect!
      post rtauthorizations_create_path, params: {token: checkout.token}

    else
      post rtauthorizations_create_path, params: {token: customer.rtbas.last.token}    
    end
    
    rtauthorization = assigns(:rtauthorization)

    return rtauthorization

  end

  def set_dropsite(customer)

    log_in_as(customer)

    get dropsites_path
    assert_template 'dropsites/index'
    get dropsite_path(Dropsite.first)
    assert_template 'dropsites/show'
    post user_dropsites_path, params: {user_dropsite: {user_id: customer.id, dropsite_id: Dropsite.first.id}}

  end

  def get_items_total_gross(customer)
    
    set_dropsite(customer)

    get tote_items_path
    assert_response :success
    assert_template 'tote_items/tote'
    assert_not_nil assigns(:tote_items)
    items_total_gross = assigns(:items_total_gross)
    assert_not_nil items_total_gross    
    assert items_total_gross > 0, "total amount of tote items is not greater than zero"
    puts "items_total_gross = $#{items_total_gross}"

    return items_total_gross

  end

  def create_posting_recurrence(posting_recurrence_frequency = nil, order_cutoff = nil, delivery_date = nil)

    posting = create_posting(create_producer("john", "john@j.com", "WA", 98033, "john@j.com", "John's Farms"), 1.25)
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

  def do_current_posting_order_cutoff_tasks(posting_recurrence)
    
    posting = posting_recurrence.current_posting
    travel_to posting.commitment_zone_start
    RakeHelper.do_hourly_tasks
    
    return posting

  end

  def do_delivery(posting)

    travel_to posting.delivery_date + 12.hours
    #log in as admin and process a fill
    log_in_as(users(:a1))
    post postings_fill_path, params: {posting_id: posting.id, quantity: posting.total_quantity_authorized_or_committed}

  end

  def nuke_all_users
    User.delete_all
    assert_equal 0, User.count
  end

  def nuke_all_postings
    Posting.delete_all
    assert_equal 0, Posting.count
  end

  def create_tote_item(posting, quantity, user)

    tote_item = ToteItem.create(user: user, posting: posting, quantity: quantity, price: posting.price, state: ToteItem.states[:ADDED])
    assert tote_item.valid?

    return tote_item

  end

  def create_posting(producer, price, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, commission = nil, order_minimum_producer_net = nil)

    if delivery_date.nil?
      delivery_date = get_delivery_date(days_from_now = 7)
    end

    if commitment_zone_start.nil?
      commitment_zone_start = delivery_date - 2.days
    end

    if product.nil?
      product = products(:apples)
    end

    if unit.nil?
      unit = units(:pound)
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

    assert posting.valid?

    return posting

  end

  def create_user(name, email, zip = nil)

    #create producer
    user = User.create!(
      name:  name,
      email: email,
      password:              "dogdog",
      password_confirmation: "dogdog",
      account_type: 0,
      activated: true,
      activated_at: Time.zone.now,
      agreement: 1,
      zip: zip,
      beta: false
      )

    assert user.valid?

    return user

  end

  def create_producer(name, email, state, zip, website, farm_name)

    producer = create_user(name, email, zip)

    producer.update(account_type: 1,
      description: "here is a description of our farm",
      state: state,
      website: website,
      farm_name: farm_name
      )

    producer.settings.update(conditional_payment: true)
    producer.create_business_interface(name: "#{name} #{name}, Inc.", order_email_accepted: true, order_email: producer.email, paypal_accepted: true, paypal_email: producer.email)

    assert producer.valid?

    return producer

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

  def get_last_wednesday

    now = Time.zone.now
    travel_back
    next_wednesday = get_next_wednesday
    last_wednesday = next_wednesday - 7.days
    travel_to now

    return last_wednesday

  end

  def get_next_wednesday

    next_wednesday = Time.zone.now.midnight
    while !next_wednesday.wednesday?
      next_wednesday += 1.day
    end

    return next_wednesday

  end
  
  def create_commission(farmer, product, unit, commission)    
    
    ppuc = ProducerProductUnitCommission.new(user: farmer, product: product, unit: unit, commission: commission)
    assert ppuc.valid?
    assert ppuc.save

    return ppuc

  end

  def get_all_mail_by_subject_to(subject, to)
    
    ret = []

    ActionMailer::Base.deliveries.each do |m|
      if m.subject == subject && m.to == [to]
        ret << m
      end      
    end

    return ret

  end

  def get_all_mail_by_subject(subject)

    all_mail = []

    ActionMailer::Base.deliveries.each do |m|
      if m.subject == subject
        all_mail << m
      end      
    end

    return all_mail

  end

  def get_mail_by_subject(subject)

    mail = nil

    ActionMailer::Base.deliveries.each do |m|
      if m.subject == subject
        mail = m
      end      
    end

    return mail

  end

  def assert_appropriate_email(mail, to, subject, body)
    assert_not mail.nil?
    assert_equal subject, mail.subject
    assert_equal [to], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match body, mail.body.encoded
  end

  def assert_not_email_to(not_to)
    ActionMailer::Base.deliveries.each do |mail|
      assert_not_equal not_to, mail.to[0]
    end
  end

  def assert_appropriate_email_exists(to, subject, body)

    email_exists = false

    ActionMailer::Base.deliveries.each do |mail|
      
      all_conditions_met = true

      if mail.from[0] != "david@farmerscellar.com"
        all_conditions_met = false
      end

      if mail.to[0] != to
        all_conditions_met = false
      end

      if mail.subject != subject
        all_conditions_met = false
      end

      if !mail.body.encoded.include?(body)
        all_conditions_met = false
      end

      if all_conditions_met
        email_exists = true
      end

    end

    assert email_exists, "Email does not exist - from: david@farmerscellar.com, to: #{to}, subject: #{subject}, body: #{body}"

  end

  # Add more helper methods to be used by all tests here...
  def is_logged_in?
  	!session[:user_id].nil?
  end

  # Logs in a test user.
  def log_in_as(user, options = {})
    password    = options[:password]    || 'dogdog'
    remember_me = options[:remember_me] || '1'
    if integration_test?
      post login_path, params: {session: { email: user.email, password: password, remember_me: remember_me }}
    else
      session[:user_id] = user.id
    end
  end

  def get_access_code    
    @a1 = users(:a1)
    log_in_as(@a1)
    post access_codes_path, params: {access_code: {notes: "empty notes"}}
    code = assigns(:code)

    return code

  end

  def get_access_for(user)
    code = get_access_code
    log_in_as(user)
    patch user_path(user), params: {user: { access_code: code }}
  end

  def get_error_messages(active_record_object)

    messages = ""

    if active_record_object.nil? || active_record_object.errors.count < 1      
      messages = "There are no activerecord errors"
      return messages
    end

    active_record_object.errors.full_messages.each do |message|
      messages += message + ", "
    end

    return messages

  end

  private

    # Returns true inside an integration test.
    def integration_test?
      defined?(post_via_redirect)
    end
  
end
