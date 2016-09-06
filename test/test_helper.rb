ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def nuke_all_postings
    Posting.delete_all
    assert_equal 0, Posting.count
  end

  def create_tote_item(posting, quantity, user)

    tote_item = ToteItem.create(user: user, posting: posting, quantity: quantity, price: posting.price, state: ToteItem.states[:ADDED])
    assert tote_item.valid?

    return tote_item

  end

  def create_posting(producer, price, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, commission = nil)

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

    assert posting.valid?

    return posting

  end

  def create_user(name, email, zip)

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
