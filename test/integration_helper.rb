require 'test_helper'
require 'utility/rake_helper'

class IntegrationHelper < ActionDispatch::IntegrationTest

  def create_posting_recurrence(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, commitment_zone_start = nil, units_per_case = nil, frequency = nil)

    if farmer.nil?
      farmer = create_producer("john", "john@j.com")
      assert farmer.valid?
      assert farmer.producer?
    end

    if product.nil?
      product = products(:apples)
    end

    if unit.nil?
      unit = units(:pound)
    end

    if !ProducerProductUnitCommission.where(user: farmer, product: product, unit: unit).any?
      create_commission(farmer, product, unit, 0.05)
    end

    if price.nil?
      price = 1.0
    end

    if delivery_date.nil?
      delivery_date = get_delivery_date(days_from_now = 7)
    end

    if commitment_zone_start.nil?
      commitment_zone_start = delivery_date - 2.days
    end

    if units_per_case.nil?
      units_per_case = 1
    end

    if frequency.nil?
      frequency = 1
    end

    posting = create_posting(farmer, price, product, unit, delivery_date, commitment_zone_start, units_per_case)
    assert posting.valid?

    posting_recurrence = PostingRecurrence.new(frequency: frequency, on: true)
    posting_recurrence.postings << posting

    assert posting_recurrence.save

    return posting.reload.posting_recurrence

  end

  def create_posting(farmer, price, product, unit, delivery_date, commitment_zone_start, units_per_case)

    posting_params = {
      description: "describe description",
      quantity_available: 100,
      price: price,
      user_id: farmer.id,
      product_id: product.id,
      unit_id: unit.id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: commitment_zone_start,
      units_per_case: units_per_case
    }

    log_in_as(farmer)
    post postings_path, params: {posting: posting_params}
    posting = assigns(:posting)
    verify_post_presence(posting.price, posting.unit, exists = true, posting.id)
    
    return posting

  end

  def create_new_customer(name, email)

    get signup_path
    ActionMailer::Base.deliveries.clear
    assert_difference 'User.count', 1 do
      post users_path, params: {user: { name: name, email: email, password: "dogdog", zip: 98033, account_type: 0 }}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)    
    assert_not user.activated?
    #log in before activation.
    log_in_as(user)
    
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!    
    get_access_for(user)
    get user_path(user)
    assert_template 'users/show'
    assert is_logged_in?

    return user

  end

  def create_one_time_authorization_for_customer(customer)    

    set_dropsite(customer)
    items_total_gross = get_items_total_gross(customer)

    post checkouts_path, params: {amount: items_total_gross, use_reference_transaction: "0"}
    checkout_tote_items = assigns(:checkout_tote_items)
    assert_not_nil checkout_tote_items
    assert checkout_tote_items.any?
    checkout = assigns(:checkout)
    assert_not_nil checkout
    puts "checkout token: #{checkout.token}"
    puts "checkout amount: #{checkout.amount}"
    assert_redirected_to new_authorization_path(token: checkout.token)    
    follow_redirect!    
    authorization = assigns(:authorization)    
    assert_not_nil authorization
    assert authorization.token = checkout.token, "authorization.token not equal to checkout.token"
    assert authorization.amount = checkout.amount, "authorization.amount not equal to checkout.token"
    assert_template 'authorizations/new'
    num_mail_messages_sent = ActionMailer::Base.deliveries.size
    post authorizations_path, params: {authorization: {token: authorization.token, payer_id: authorization.payer_id, amount: authorization.amount}}
    authorization = assigns(:authorization)
    verify_authorization_receipt_sent(num_mail_messages_sent, customer, authorization)
    assert_not_nil authorization
    assert_not_nil authorization.transaction_id
    assert_template 'authorizations/create'
   
    return authorization

  end

  def create_tote_item(customer, posting, quantity, frequency = nil, roll_until_filled = nil)
 
    log_in_as(customer)
    assert is_logged_in?

    post tote_items_path, params: {tote_item: {quantity: quantity, posting_id: posting.id}}
    tote_item = assigns(:tote_item)

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

    return tote_item.reload

  end

  def setup_basic_subscription_through_delivery

    nuke_all_postings

    delivery_date = get_delivery_date(days_from_now = 10)
    if (delivery_date - 1.day).sunday?
      delivery_date += 1.day
    end
    commitment_zone_start = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.settings.update(conditional_payment: false)
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)

    #maybe we can/will parameterize this later?
    if false
      distributor.update(order_minimum_producer_net: 20)
    end

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor    
    producer1.save
    
    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting_recurrence(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1, frequency = 1).current_posting

    bob = create_user("bob", "bob@b.com")
    
    ti1_bob = create_tote_item(bob, posting1, 2, subscription_frequency = 1)

    create_rt_authorization_for_customer(bob)

    assert_equal 1, bob.tote_items.count    
    ti = bob.tote_items.first

    assert_equal 1, Posting.count
    posting = Posting.first

    num_units = ti.quantity
    
    travel_to posting.commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    assert_equal 1, ActionMailer::Base.deliveries.count
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.last, posting.get_creditor, posting, num_units, units_per_case = "", number_of_cases = "")

    #do fill
    travel_to posting.delivery_date + 12.hours

    fill_posting(posting.reload, num_units)

    #distributor posting should be closed
    assert posting.reload.state?(:CLOSED)

    #send out delivery notifications
    ActionMailer::Base.deliveries.clear
    do_delivery
    
    #verify delivery notification is correct
    assert_equal 1, ActionMailer::Base.deliveries.count

    verify_proper_delivery_notification_email(ActionMailer::Base.deliveries.first, ti.reload)
    assert ti.reload.state?(:FILLED)

    return bob

  end

  def setup_basic_process_through_delivery

    nuke_all_postings

    delivery_date = get_delivery_date(days_from_now = 10)
    if (delivery_date - 1.day).sunday?
      delivery_date += 1.day
    end
    commitment_zone_start = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.settings.update(conditional_payment: false)
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)

    #maybe we can/will parameterize this later?
    if false
      distributor.update(order_minimum_producer_net: 20)
    end

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor    
    producer1.save
    
    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1)

    bob = create_user("bob", "bob@b.com")
    
    ti1_bob = create_tote_item(bob, posting1, 2)

    create_one_time_authorization_for_customer(bob)

    assert_equal 1, bob.tote_items.count    
    ti = bob.tote_items.first

    assert_equal 1, Posting.count
    posting = Posting.first

    num_units = ti.quantity
    
    travel_to posting.commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    assert_equal 1, ActionMailer::Base.deliveries.count
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.last, posting.get_creditor, posting, num_units, units_per_case = "", number_of_cases = "")

    #do fill
    travel_to posting.delivery_date + 12.hours

    fill_posting(posting.reload, num_units)

    #distributor posting should be closed
    assert posting.reload.state?(:CLOSED)

    #send out delivery notifications
    ActionMailer::Base.deliveries.clear
    do_delivery
    
    #verify delivery notification is correct
    assert_equal 1, ActionMailer::Base.deliveries.count

    verify_proper_delivery_notification_email(ActionMailer::Base.deliveries.first, ti.reload)
    assert ti.reload.state?(:FILLED)

    return bob

  end



  def verify_post_presence(price, unit, exists, posting_id = nil)

    if exists == true
      count = 1
    else
      count = 0
    end

    verify_post_visibility(price, unit, count)    
    verify_post_existence(price, count, posting_id)

  end

  def verify_post_visibility(price, unit, count)
    get postings_path
    assert :success
    assert_select "body div.panel h4.panel-title", {text: ActiveSupport::NumberHelper.number_to_currency(price) + " / " + unit.name, count: count}
  end

  def verify_post_existence(price, count, posting_id = nil)

    postings = Posting.where(price: price)
    assert_not postings.nil?
    assert_equal count, postings.count

    if posting_id != nil
      assert_equal posting_id, postings.last.id
    end

  end



  def verify_authorization_receipt_sent(num_mail_messages_sent, user, authorization)

    #did a mail message even go out?
    assert_equal ActionMailer::Base.deliveries.size, num_mail_messages_sent + 1

    mail = ActionMailer::Base.deliveries.last
    assert_equal [user.email], mail.to
    assert_match "Authorization receipt", mail.subject    
    assert_match "This is your Farmer's Cellar receipt for payment authorization", mail.body.encoded
    
    assert_match authorization.checkouts.last.tote_items.last.posting.user.farm_name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.product.name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.price.to_s, mail.body.encoded
    assert authorization.checkouts.last.tote_items.last.price > 0
    assert authorization.checkouts.last.tote_items.last.quantity > 0
    assert_match authorization.checkouts.last.tote_items.last.quantity.to_s, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.unit.name, mail.body.encoded
    assert_match authorization.checkouts.last.tote_items.last.posting.delivery_date.strftime("%A %b %d, %Y"), mail.body.encoded

    assert authorization.amount > 0
    assert_match authorization.amount.to_s, mail.body.encoded

  end

  #the order submission email has columns for Units per Case, Number of Cases and Number of Units
  #you might want to make your test cases such that each value should be an unique number so that
  #the tests are meaningful
  def verify_proper_order_submission_email(mail, creditor, posting, number_of_units, units_per_case, number_of_cases)

    business_interface = creditor.get_business_interface

    subject = "Current orders for upcoming deliveries"

    if business_interface.order_email_accepted
      email = business_interface.order_email
    else
      email = "david@farmerscellar.com"
      subject = "admin action required: " + subject
    end

    assert_equal [email], mail.to
    assert_match subject, mail.subject
    assert_match number_of_units.to_s, mail.body.encoded
    assert_match units_per_case.to_s, mail.body.encoded
    assert_match number_of_cases.to_s, mail.body.encoded

  end

  def fill_posting(posting, quantity)
    a1 = users(:a1)
    log_in_as(a1)
    assert is_logged_in?
    assert posting.reload.state?(:COMMITMENTZONE)
    post postings_fill_path, params: {posting_id: posting.id, quantity: quantity}
    assert posting.reload.state?(:CLOSED)

    #TODO: do something smart here with the fill_report. maybe some legitimacy checks?
    fill_report = assigns(:fill_report)
  end

  def do_delivery

    a1 = users(:a1)
    log_in_as(a1)

    get new_delivery_path
    assert :success
    assert_template 'deliveries/new'
    delivery_eligible_postings = assigns(:delivery_eligible_postings)
    dropsites = assigns(:dropsites)
    assert delivery_eligible_postings.count > 0
    assert dropsites.count > 0

    delivery_count = Delivery.count
    ids = []
    delivery_eligible_postings.each do |posting|
      ids << posting.id
    end

    post deliveries_path, params: {posting_ids: ids}
    delivery = assigns(:delivery)
    assert_redirected_to delivery_path(delivery)
    follow_redirect!
    assert_template 'deliveries/show'
    assert_not flash.empty?
    assert_select 'a', "Edit Delivery"
    get edit_delivery_path(delivery)
    assert_template 'deliveries/edit'
    dropsites_deliverable = assigns(:dropsites_deliverable)

    dropsites_deliverable.each do |dropsite|
      patch delivery_path(delivery), params: {dropsite_id: dropsite.id}
    end

  end

  def all_tote_items_fully_filled?(tote_items)

    if tote_items.nil?
      return true
    end

    tote_items.each do |tote_item|
      if !tote_item.fully_filled?
        return false
      end
    end

    return true

  end

  #the order submission email has columns for Units per Case, Number of Cases and Number of Units
  #you might want to make your test cases such that each value should be an unique number so that
  #the tests are meaningful
  def verify_proper_delivery_notification_email(mail, tote_item, all_tote_items_in_this_delivery_notification = nil)

    if tote_item.fully_filled? && all_tote_items_fully_filled?(all_tote_items_in_this_delivery_notification)
      subject = "Delivery notification"
    else
      subject = "Unfilled order(s) and delivery notification"
    end    

    email = tote_item.user.email

    assert_equal [email], mail.to
    assert_match subject, mail.subject

    assert_match tote_item.quantity_filled.to_s, mail.body.encoded

    if (tote_item.fully_filled? || tote_item.partially_filled?) && tote_item.state?(:FILLED)
      assert_match "DELIVERED", mail.body.encoded
    end

    if tote_item.zero_filled? && tote_item.state?(:NOTFILLED)
      assert_match "NOT DELIVERED", mail.body.encoded
    end

    if (tote_item.partially_filled? || tote_item.zero_filled?) && (tote_item.state?(:NOTFILLED) || tote_item.state?(:FILLED))
      assert_match "Important Message!", mail.body.encoded      
    end

  end
  
  #the tote_items passed should be all the items you expect to be represented in a single purchase receipt
  def verify_purchase_receipt_email(tote_items)

    subject = "Purchase receipt"

    assert_not tote_items.nil?
    assert tote_items.any?

    #get the purchase receipt(s) for this user
    to = tote_items.first.user.email
    purchase_receipts = get_all_mail_by_subject_to(subject, to)
    assert_not purchase_receipts.nil?
    assert_equal 1, purchase_receipts.count
    receipt = purchase_receipts.first
    #verify the subject and to are correct
    assert_equal [to], receipt.to
    assert_match subject, receipt.subject

    #verify generic stuff and table column headers
    assert_match "Here is your Farmer's Cellar purchase receipt.", receipt.body.encoded
    assert_match "ID", receipt.body.encoded
    assert_match "Producer", receipt.body.encoded
    assert_match "Product", receipt.body.encoded
    assert_match "Delivery Date", receipt.body.encoded
    assert_match "Price", receipt.body.encoded
    assert_match "Quantity", receipt.body.encoded
    assert_match "Sub Total", receipt.body.encoded
    assert_match "Thanks!", receipt.body.encoded
    assert_match "farmerscellar.com/news", receipt.body.encoded            
    
    #verify the dollar figures
    verify_amounts(receipt, tote_items)

  end

  def verify_pickup_deadline_reminder_email(mail, user, tote_items, partner_deliveries)

    assert mail
    assert user
    assert (tote_items && tote_items.any?) || (partner_deliveries && partner_deliveries.any?)
    assert_equal user.email, mail.to[0]
    assert_equal "Pickup deadline reminder", mail.subject

    assert_match "Have you picked up these products yet?", mail.body.encoded

    if tote_items && tote_items.any?
      ti = tote_items.first
      assert_match ti.posting.user.farm_name, mail.body.encoded
      assert_match ti.quantity_filled.to_s, mail.body.encoded
    end

    if partner_deliveries && partner_deliveries.any?
      assert_match partner_deliveries.first.partner, mail.body.encoded
    end

    assert_match "Our records suggest they might remain at the dropsite. If so, please plan to pick them up before 8PM tonight (i.e.", mail.body.encoded
    assert_match "Otherwise they'll be removed and donated", mail.body.encoded

    if user.pickups.any?
      assert_match "FYI, your last recorded pickup was #{user.pickups.last.created_at.strftime("%A %B %d, %Y at %l:%M %p")}", mail.body.encoded
    end

    assert_match "farmerscellar.com/news", mail.body.encoded

  end

  def verify_amounts(purchase_receipt, tote_items)

    assert_not tote_items.nil?
    assert tote_items.any?

    purchase_total = 0

    tote_items.each do |tote_item|
      purchase_total = (purchase_total + verify_purchase_sub_total(purchase_receipt, tote_item)).round(2)
    end

    assert_match "Your payment account was charged a total of #{number_to_currency(purchase_total)}.", purchase_receipt.body.encoded

    return purchase_total

  end

  def verify_purchase_sub_total(purchase_receipt, tote_item)

    assert_not tote_item.nil?

    sub_total = 0

    if !tote_item.state?(:FILLED)      
      return sub_total
    end

    assert_match tote_item.posting.user.farm_name, purchase_receipt.body.encoded
    assert_match tote_item.posting.product.name, purchase_receipt.body.encoded
    assert_match number_to_currency(tote_item.price), purchase_receipt.body.encoded
    assert_match tote_item.posting.unit.name, purchase_receipt.body.encoded
    assert_match tote_item.quantity_filled.to_s, purchase_receipt.body.encoded

    sub_total = get_gross_item(tote_item, filled = true)

    return sub_total

  end

  def verify_payment_receipt_email(postings)
    payment_receipt_mail = get_mail_by_subject("Payment receipt")
    
    bi = postings.first.user.get_business_interface
    subject = "Payment receipt"    

    if bi.paypal_accepted
      email = bi.paypal_email
    else
      email = "david@farmerscellar.com"
      subject = "admin action required: " + subject
    end

    #verify proper email and subject
    assert_equal [email], payment_receipt_mail.to
    assert_match subject, payment_receipt_mail.subject

    #verify proper summary statement
    payment_total = verify_producer_payment(postings)    
    summary = "We just sent you a total of #{number_to_currency(payment_total)} as payment for the following products"
    assert_match summary, payment_receipt_mail.body.encoded

    #verify all the subtotal values exist
    postings.each do |posting|
      sub_total = get_payment_subtotal(posting)
      assert_match number_to_currency(sub_total), payment_receipt_mail.body.encoded
    end

  end

  #pass an array of postings that all belong to the same producer and that all got paid on at the same time
  def verify_producer_payment(postings)

    payment_total = 0

    postings.each do |posting|
      sub_total = get_payment_subtotal(posting)
      payment_total = (payment_total + sub_total).round(2)
    end
    
    return payment_total

  end

  def get_payment_subtotal(posting)

    sub_total = 0

    posting.tote_items.each do |tote_item|

      if tote_item.state?(:FILLED)

        computed_purchase_value = get_gross_item(tote_item, filled = true)
        recorded_purchase_value = tote_item.purchase_receivables.last.purchases.last.gross_amount
        assert_equal computed_purchase_value, recorded_purchase_value
        assert_equal recorded_purchase_value, tote_item.purchase_receivables.last.amount
        assert_equal tote_item.purchase_receivables.last.amount, tote_item.purchase_receivables.last.amount_purchased

        computed_payment_value = get_producer_net_item(tote_item, filled = true)
        recorded_payment_value = tote_item.payment_payables.last.payments.last.amount
        assert_equal computed_payment_value, recorded_payment_value

        sub_total = (sub_total + computed_payment_value).round(2)

      end

    end

    return sub_total

  end
  
end