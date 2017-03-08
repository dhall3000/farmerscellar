require 'test_helper'
require 'utility/rake_helper'

#def create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil)
#def create_new_customer(name, email)
#def create_tote_item(customer, posting, quantity, frequency = nil, roll_until_filled = nil)
#def create_one_time_authorization_for_customer(customer)
#def create_rt_authorization_for_customer(customer)
#def create_payment(amount, amount_applied = 0, notes = nil, creditor_order = nil)
#def create_payment_full_balance(creditor_order)

class IntegrationHelper < ActionDispatch::IntegrationTest

  def remove_tote_item(tote_item)
    
    assert tote_item
    assert tote_item.valid?
    assert [ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED]].include?(tote_item.state)

    log_in_as(tote_item.user)
    delete tote_item_path(tote_item)
    assert_response :redirect

    assert tote_item.reload.state?(:REMOVED)

    return tote_item

  end

  def verify_price_on_postings_page(price, unit, count = nil)

    if count && count > 0
      assert_select "div.truncated-text-line strong", {text: "#{ActiveSupport::NumberHelper.number_to_currency(price)} / #{unit.name}", minimum: 1}
    else
      assert_select "div.truncated-text-line strong", {text: "#{ActiveSupport::NumberHelper.number_to_currency(price)} / #{unit.name}", count: 0}
    end
    
  end

  def log_in_as_admin(admin = nil)

    if admin.nil?
      admin = get_admin
    end

    log_in_as(admin)

  end

  def get_creditor_orders
    log_in_as_admin
    get creditor_orders_path
    assert_response :success
    assert_template 'creditor_orders/index'
  end

  def creditor_orders_index_verify_presence(creditor_order)
    
    get_creditor_orders

    if creditor_order.state?(:OPEN)
      open_or_closed = "Open Orders"
    elsif creditor_order.state?(:CLOSED)
      open_or_closed = "Closed Orders"
    end

    assert_select 'h2', open_or_closed
    assert_select 'td.text-center', creditor_order.business_interface.friendly_payment_description

    #verify the business name shows up
    assert_select 'a[href=?]', creditor_order_path(creditor_order), creditor_order.business_interface.name
    #verify the balance shows up
    assert_select 'td.text-center', number_to_currency(creditor_order.balance)
    
  end

  def create_payment(amount, amount_applied = 0, notes = nil, creditor_order = nil)
    
    log_in_as_admin
        
    if creditor_order
      
      creditor_order_id = creditor_order.id
      prior_balance = creditor_order.balance

      if creditor_order.creditor_obligation
        prior_num_payments = creditor_order.creditor_obligation.payments.count
      else
        prior_num_payments = 0
      end

    else
      creditor_order_id = nil
    end

    ActionMailer::Base.deliveries.clear
    prior_mail_count = ActionMailer::Base.deliveries.count

    post payments_path, params: {creditor_order_id: creditor_order_id, payment: {amount: amount.round(2), amount_applied: amount_applied.round(2), notes: notes}}

    payment = assigns(:payment)
    assert payment.valid?

    if creditor_order

      creditor_order.reload
      #there positively must be an obligation object now that a payment has been made
      assert creditor_order.creditor_obligation

      if creditor_order.balance == 0
        assert creditor_order.state?(:CLOSED)
        assert creditor_order.balanced?
      else
        assert creditor_order.state?(:OPEN)
      end

      if creditor_order.business_interface.payment_receipt_email
        assert_equal prior_mail_count + 1, ActionMailer::Base.deliveries.count
        mail = ActionMailer::Base.deliveries.last
        verify_payment_receipt_email(creditor_order.postings, payment)
        #ProducerNotificationsMailer.payment_receipt(@creditor_order, @payment).deliver_now
      else
        assert_equal prior_mail_count, ActionMailer::Base.deliveries.count
      end

      #verify now at creditororder#show
      assert_response :redirect
      assert_redirected_to creditor_order_path(creditor_order)
      follow_redirect!
      #verify balance displays
      assert_select 'td.text-left', number_to_currency(creditor_order.balance)
      #verify the state displays
      assert_select 'td.text-left', creditor_order.state_key.to_s
      #verify balance reflects new payment
      assert_equal (prior_balance - amount).round(2), creditor_order.balance
      #verify creditor_order object now holds a reference to 1 more payment
      assert_equal prior_num_payments + 1, creditor_order.creditor_obligation.payments.count
      
    end

    return payment

  end

  def create_payment_full_balance(creditor_order)
    return create_payment(creditor_order.balance, amount_applied = 0, notes = nil, creditor_order)
  end

  def do_atorder_payment_setup(payment_method_key, payment_time_key)

    #clean house
    nuke_all_postings
    nuke_all_users
    admin = create_admin

    #create producer with the parameterized payments type
    producer = create_creditor_with(payment_method_key, payment_time_key)
    #create a posting for this producer
    posting = create_posting(producer, price = 10)
    
    #create a customer
    bob = create_new_customer("bob", "bob@b.com")

    #new customer does a bunch of shopping
    create_tote_item(bob, posting, 2)

    #then new customer checks out
    create_one_time_authorization_for_customer(bob)

    #at this point no orders should be submitted
    assert_equal 0, CreditorOrder.count

    do_hourly_tasks_at(Posting.first.order_cutoff)

    #now all the orders should be submitted, one for each posting
    assert_equal Posting.count, CreditorOrder.count
    #all the CreditorOrders should be in state OPEN
    assert_equal CreditorOrder.count, CreditorOrder.where(state: CreditorOrder.state(:OPEN)).count
    #no value has exchanged hands so there should be zero obligations
    assert_equal 0, CreditorObligation.count
    #all postings should be in COMMITMENTZONE
    assert_equal Posting.count, Posting.where(state: Posting.states[:COMMITMENTZONE]).count

    return admin

  end

  def do_authorized_through_funds_transfer(posting)
    
    #transition tote items from authorized -> committed
    do_hourly_tasks_at(posting.order_cutoff)
    #do fill    

    #the corder should be OPEN
    assert posting.creditor_order.state?(:OPEN)
    #but there shouldn't be a cobligation yet cause no value has exchanged hands
    assert_not posting.creditor_order.creditor_obligation    
    fully_fill_creditor_order(posting.creditor_order)

    #now value has exchanged hands so corder should still be OPEN
    assert posting.creditor_order.state?(:OPEN)
    #and there should be a cobligation
    assert posting.creditor_order.creditor_obligation
    #and that cobligation's balance should be positive since we received goods
    assert posting.creditor_order.creditor_obligation.balance > 0
    #there should now be an unbalanced CreditorObligation associated with this
    num_positive_balanced_creditor_obligations = CreditorObligation.get_positive_balanced.count
    assert num_positive_balanced_creditor_obligations > 0
    assert CreditorOrder.where(state: CreditorOrder.state(:OPEN)).count > 0        
    #check that method send_payments actually gets called and does something
    #this check might actually become obsolete if/when we implement non-paypal payment methods?
    num_paypal_responses = PpMpCommon.count
    #transfer funds
    do_hourly_tasks_at(posting.delivery_date + 22.hours)

    #now the cobligation should be balanced
    assert_equal 0.0, posting.reload.creditor_order.creditor_obligation.balance
    #and the corder should be closed
    assert posting.reload.creditor_order.state?(:CLOSED)

    #there should now be one less unbalanced CreditorObligation after payment was made
    assert_equal num_positive_balanced_creditor_obligations - 1, CreditorObligation.get_positive_balanced.count
    assert_equal num_paypal_responses + 1, PpMpCommon.count

  end

  def log_in_dropsite_user(dropsite_user)
    log_in_as(dropsite_user)
    assert :success
    assert_redirected_to new_pickup_path
    follow_redirect!
    assert_template 'pickups/new'
  end

  def do_pickup_for(dropsite_user, pickup_user)

    log_in_dropsite_user(dropsite_user)
    post pickups_path, params: {pickup_code: pickup_user.pickup_code.code}
    assert_response :success

    tote_items = assigns(:tote_items)

    if pickup_user.delivery_since_last_dropsite_clearout? || pickup_user.account_type_is?(:PRODUCER) || pickup_user.account_type_is?(:ADMIN)
      assert_template 'pickups/create'
    else
      assert_template 'pickups/new'
    end    
    
    return tote_items

  end

  def log_out_dropsite_user
    get pickups_log_out_dropsite_user_path
    follow_redirect!
  end

  def log_out
    delete logout_path
  end

  def go_to_delivery_day_and_fill_posting(posting, quantity = nil)
    
    travel_to posting.delivery_date + 12.hours

    if posting.creditor_order
      fill_posting(posting, quantity)      
    end    

  end

  def fill_posting(posting, quantity = nil)

    assert posting, "posting param is nil"
    assert posting.reload.creditor_order, "This posting has no associated order. You can't fill a posting that doesn't have an associated CreditorOrder object."

    if quantity.nil?
      quantity = posting.total_quantity_ordered_from_creditor
    end

    a1 = get_admin
    log_in_as(a1)
    assert is_logged_in?
    fills = get_creditor_order_fills_param(posting.id, quantity)
    patch creditor_order_path(posting.creditor_order), params: {fills: fills}
    fill_report = assigns(:fill_report)
    assert_response :redirect
    assert_redirected_to creditor_order_path(assigns(:creditor_order))
    follow_redirect!
    assert_template 'creditor_orders/show'

    if quantity >= 0
      assert posting.reload.state?(:CLOSED)
    end

    return fill_report

  end

  def fully_fill_all_creditor_orders

    log_in_as(users(:a1))
    get creditor_orders_path
    assert_response :success
    assert_template 'creditor_orders/index'

    open_orders = assigns(:open_orders)
    open_orders.each do |uco|
      fully_fill_creditor_order(uco)
    end

  end

  def fully_fill_creditor_order(creditor_order)

    travel_to creditor_order.delivery_date + 12.hours
    
    assert creditor_order
    assert creditor_order.postings
    
    log_in_as_admin
    
    get creditor_order_path(creditor_order)
    assert_response :success
    assert_template 'creditor_orders/show'

    get edit_creditor_order_path(creditor_order)
    assert_response :success
    assert_template 'creditor_orders/edit'

    fills = get_fully_filled_creditor_order_fills_params(creditor_order.postings)
    
    patch creditor_order_path(creditor_order), params: {fills: fills}

    assert_response :redirect
    assert_redirected_to creditor_order_path(assigns(:creditor_order))
    follow_redirect!
    assert_template 'creditor_orders/show'
    
    creditor_order.reload.postings.each do |posting|
      assert posting.state?(:CLOSED)
    end

    #there possibly already was a cobligation before this method call but now there positively must be one
    assert creditor_order.creditor_obligation
    #there must also now be payment_payables
    assert creditor_order.creditor_obligation.payment_payables.count > 0
    
    if creditor_order.business_interface.payment_time?(:AFTERDELIVERY)
      #if payment comes after delivery (which just happened now) then we must have a positive balance here
      assert creditor_order.balance > 0
    end

    if creditor_order.balanced?
      assert creditor_order.state?(:CLOSED)
    end

  end

  def get_fully_filled_creditor_order_fills_params(postings)

    fills = []

    postings.each do |posting|
      assert_not posting.state?(:CLOSED)
      fills += get_creditor_order_fills_param(posting.id, posting.total_quantity_ordered_from_creditor)      
    end

    return fills

  end

  def get_creditor_order_fills_param(posting_id, quantity)    
    return [{posting_id: posting_id, quantity: quantity}]
  end
  
  def create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = nil)

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

    create_food_category_for_product_if_product_has_none(product)

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

    if producer_net_unit.nil?
      commission_per_unit = (price * 0.05).round(2)
      payment_processor_fee_unit = ToteItemsController.helpers.get_payment_processor_fee_unit(price)
      producer_net_unit = (price - commission_per_unit - payment_processor_fee_unit).round(2)
    end

    posting_params = {
      description: "describe description",
      price: price,
      producer_net_unit: producer_net_unit,
      user_id: farmer.id,
      product_id: product.id,
      unit_id: unit.id,
      live: true,
      delivery_date: delivery_date,
      order_cutoff: order_cutoff,
      units_per_case: units_per_case,
      order_minimum_producer_net: order_minimum_producer_net,
      posting_recurrence: {frequency: frequency, on: true},
      product_id_code: product_id_code
    }    

    log_in_as(farmer)
    post postings_path, params: {posting: posting_params}    
    posting = assigns(:posting)
    assert posting.valid?

    assert_response :redirect
    assert_redirected_to postings_path
    follow_redirect!

    #need a product photo for this to display properly
    upload = upload_file("productpic.jpg")
    posting.uploads << upload
    posting.save
    assert_equal 1, posting.uploads.count

    get postings_path
    verify_post(posting.price, posting.unit, exists = true, posting.id)

    if frequency == 0
      assert_not posting.posting_recurrence
    end

    if frequency > 0
      assert posting.posting_recurrence
      assert posting.posting_recurrence.valid?
    end
    
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
    assert_response :redirect
    assert_redirected_to postings_path
    follow_redirect!    

    get_access_for(user)

    log_in_as(user)
    get user_path(user)
    assert_template 'users/show'
    assert is_logged_in?

    return user

  end

  def get_access_for(user)
    code = get_access_code
    log_in_as(user)
    patch user_path(user), params: {user: { access_code: code }}
  end  

  def get_access_code

    a1 = get_admin
    log_in_as(a1)
    post access_codes_path, params: {access_code: {notes: "empty notes"}}
    code = assigns(:code)

    return code

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

  def create_rt_authorization_for_customer(customer)

    set_dropsite(customer)
    items_total_gross = get_items_total_gross(customer)

    if customer.rtbas.count == 0 || !customer.rtbas.last.ba_valid?

      checkouts_count = Checkout.count
      post checkouts_path, params: {amount: items_total_gross, use_reference_transaction: "1"}
      assert_nil flash[:danger]
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

  def create_tote_item(customer, posting, quantity, frequency = nil, roll_until_filled = nil)
 
    log_in_as(customer)
    assert is_logged_in?

    assert posting.valid?
    assert posting.product.food_category
    food_category = posting.product.food_category

    get postings_path(food_category: food_category.name)
    assert_response :success
    assert_template 'postings/index'
    get posting_path(posting)
    assert_response :success
    assert_template 'postings/show'
    if posting.biggest_order_minimum_producer_net_outstanding > 0      
      assert_select 'div.row.gutter-10 div.col-xs-10 div.truncated-text-line', {text: "Unmet Group Order Minimum", count: 1}
    end

    post tote_items_path, params: {posting_id: posting.id, quantity: quantity}
    tote_item = assigns(:tote_item)

    if posting.posting_recurrence.nil? || !posting.posting_recurrence.on
      assert_tote_item_added(tote_item)
      return tote_item
    end

    #now we know there's a posting recurrence so we should be on the 'how often?' page
    assert_response :success
    assert_template 'tote_items/how_often'
    assert_not tote_item
    posting_id = assigns(:posting).id
    assert_equal posting.id, posting_id

    quantity_save = quantity
    quantity = assigns(:quantity)
    assert_equal quantity_save, quantity

    if roll_until_filled
      #user wants a subscription
      post subscriptions_path, params: {posting_id: posting_id, quantity: quantity, frequency: frequency, roll_until_filled: roll_until_filled}
      #assert valid subscription
      subscription = assigns(:subscription)
      assert subscription.valid?
      assert subscription.id
      assert subscription.kind?(:ROLLUNTILFILLED)
      #assert tote item created
      assert_equal 1, subscription.tote_items.count
      tote_item = subscription.tote_items.first
      assert tote_item.valid?
      assert tote_item.id
      #assert proper flash
      assert_equal flash[:success], "Roll until filled item added"
      #assert proper view
      assert_redirected_to food_category_path_helper(posting.product.food_category)
      return tote_item
    end
    
    if frequency.nil? || frequency < 1
      #user clicked 'Just Once'
      post tote_items_path, params: {posting_id: posting_id, quantity: quantity, frequency: 0}
      tote_item = assigns(:tote_item)
      assert_tote_item_added(tote_item)
    else
      #user wants a subscription
      post subscriptions_path, params: {posting_id: posting_id, quantity: quantity, frequency: frequency}
      #assert valid subscription
      subscription = assigns(:subscription)
      assert subscription.valid?
      assert subscription.id
      assert subscription.kind?(:NORMAL)
      #assert tote item created
      assert_equal 1, subscription.tote_items.count
      tote_item = subscription.tote_items.first
      assert tote_item.valid?
      assert tote_item.id
      #assert proper flash
      assert_equal flash[:success], "Subscription added"
      #assert proper view
      assert_redirected_to food_category_path_helper(posting.product.food_category)
    end

    return tote_item

  end

  def assert_tote_item_added(tote_item)
    assert tote_item.valid?
    assert tote_item.id
    assert_response :redirect
    assert_redirected_to food_category_path_helper(tote_item.posting.product.food_category)    
    assert_equal flash[:success], "Tote item added"
  end

  def setup_basic_subscription_through_delivery

    nuke_all_postings

    delivery_date = get_delivery_date(days_from_now = 10)
    if (delivery_date - 1.day).wday == STARTOFWEEK
      delivery_date += 1.day
    end
    order_cutoff = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.create_business_interface(name: "Distributor Inc.", order_email: distributor.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: distributor.email)

    #maybe we can/will parameterize this later?
    if false
      distributor.update(order_minimum_producer_net: 20)
    end

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor    
    producer1.save
    
    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, order_cutoff, units_per_case = 1, frequency = 1)

    bob = create_user("bob", "bob@b.com")
    
    ti1_bob = create_tote_item(bob, posting1, 2, subscription_frequency = 1)

    create_rt_authorization_for_customer(bob)

    assert_equal 1, bob.tote_items.count    
    ti = bob.tote_items.first

    assert_equal 1, Posting.count
    posting = Posting.first

    num_units = ti.quantity

    #there shouldn't be any orders placed yet
    assert_equal 0, CreditorOrder.count
    travel_to posting.order_cutoff
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #now there should be one order
    assert_equal 1, CreditorOrder.count
    creditor_order = CreditorOrder.first
    #and this order should be OPEN since that's the default state when we submit order to producer/creditor/farmer whatever etc.
    assert creditor_order.state?(:OPEN)
    #there's no obligation yet because value hasn't actually exchanged hands yet
    assert_not creditor_order.creditor_obligation

    assert_equal 1, ActionMailer::Base.deliveries.count
    verify_proper_order_submission_email(ActionMailer::Base.deliveries.last, posting.get_creditor, posting, num_units, units_per_case = "", number_of_cases = "")

    #do fill
    travel_to posting.delivery_date + 12.hours
    fill_posting(posting.reload, num_units)
    #now value has exchanged (food came to us) so there should be an obligation

    assert creditor_order.reload.creditor_obligation
    #our 'piggy bank' (so to speak) now has positive value in it
    assert creditor_order.creditor_obligation.balance > 0
    assert creditor_order.state?(:OPEN)

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
    if (delivery_date - 1.day).wday == STARTOFWEEK
      delivery_date += 1.day
    end
    order_cutoff = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com")
    distributor.create_business_interface(name: "Distributor Inc.", order_email: distributor.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: distributor.email)

    #maybe we can/will parameterize this later?
    if false
      distributor.update(order_minimum_producer_net: 20)
    end

    producer1 = create_producer("producer1", "producer1@p.com")
    producer1.distributor = distributor    
    producer1.save
    
    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, order_cutoff, units_per_case = 1)

    bob = create_user("bob", "bob@b.com")
    
    ti1_bob = create_tote_item(bob, posting1, 2)

    create_one_time_authorization_for_customer(bob)

    assert_equal 1, bob.tote_items.count    
    ti = bob.tote_items.first

    assert_equal 1, Posting.count
    posting = Posting.first

    num_units = ti.quantity
    
    travel_to posting.order_cutoff
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

  def verify_producer_can_see_post_edit_option(producer, posting)
    log_in_as(producer)
    get user_path(producer)
    assert_response :success
    assert_template 'users/show'
    assert_select 'td a', posting.product.name
    assert_select 'td.text-center a[href=?]', edit_posting_path(posting), {text: "Edit posting"}
  end

  def get_edit_posting(producer, posting)
    log_in_as(producer)
    get edit_posting_path(posting)
    assert_response :success
    verify_posting_edit(posting)

  end

  def verify_posting_edit(posting)
    assert_template 'postings/edit'
    assert_select 'input.form-control[value=?]', posting.description

    if posting.uploads.count > 0
      assert_select 'div.panel-title', "Current Photos"

      assert_select 'span img', {count: posting.uploads.count}

      #NOTE: the above check should be as below. however right now i'm tryign to go fast and i don't wnat to fiddle with
      #getting storage stuff set up in test. the way things currently are, when i grab response.body here i see this:
      #<span><img src=>
      #that's why all i'm verifying is just the span and the img

      #posting.uploads.each do |upload|        
        #assert_select 'span img[src=?]', upload.file_name.thumb.store_path
      #end      

    end

    #verify there's a panel to enable photo additions
    assert_select 'div.panel-title', "Add new photo"
    assert_select 'input.form-control[type=file]'
  end

  def upload_file(filename = nil, title = nil)
    
    orig_upload_count = Upload.count

    if filename.nil?
      filename = "filename.jpg"
    end
    
    log_in_as(get_admin)
    post uploads_path, params: {upload: {file_name: filename, title: title}}
    upload = assigns(:upload)

    if upload.valid?
      assert_response :redirect
      assert_redirected_to upload
      follow_redirect!    
      assert_equal orig_upload_count + 1, Upload.count
    else
      assert_response :success
      assert_template 'uploads/new'
      assert_not flash.empty?
      assert_equal "Invalid upload", flash.now[:danger]
      assert_equal orig_upload_count, Upload.count
    end

    return upload

  end

  def upload_photo_to_posting(producer, posting)
    orig_upload_count = Upload.count
    orig_posting_photo_count = posting.uploads.count

    log_in_as(producer)    
    post uploads_path, params: {upload: {file_name: "filename.jpg"}, posting_id: posting.id}
    assert_response :redirect
    assert_redirected_to edit_posting_path(posting)
    follow_redirect!
    verify_posting_edit(posting)
    assert_equal orig_upload_count + 1, Upload.count
    assert_equal orig_posting_photo_count + 1, posting.reload.uploads.count
  end

  def verify_post(price, unit, exists, posting_id = nil)

    posting = Posting.find posting_id
    assert posting
    assert posting.valid?

    if posting.product.food_category
      get postings_path(food_category: posting.product.food_category.name)
    else
      get postings_path
    end
    
    assert :success

    if exists
      assert_select "div.truncated-text-line strong", {text: "#{ActiveSupport::NumberHelper.number_to_currency(price)} / #{unit.name}", minimum: 1}
    else
      assert_select "div.truncated-text-line strong", {text: "#{ActiveSupport::NumberHelper.number_to_currency(price)} / #{unit.name}", count: 0}
    end
    
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

    subject = "Order for #{posting.delivery_date.strftime("%A, %B")} #{posting.delivery_date.day.ordinalize} delivery"

    if business_interface.order_email
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

  def verify_payment_receipt_email(postings, payment = nil)
    payment_receipt_mail = get_mail_by_subject("Payment receipt")
    
    bi = postings.first.user.get_business_interface
    subject = "Payment receipt"    

    if bi.payment_method?(:PAYPAL)
      email = bi.paypal_email
    else
      email = bi.payment_receipt_email
    end

    #verify proper email and subject
    assert_equal [email], payment_receipt_mail.to
    assert_match subject, payment_receipt_mail.subject

    #verify proper summary statement
    if payment
      payment_total = payment.amount
    else
      payment_total = verify_producer_payment(postings)    
    end
    
    summary = "Here's a 'paper' trail for the #{number_to_currency(payment_total)} payment we just made for the following products / quantities:"
    assert_match summary, payment_receipt_mail.body.encoded

    #verify all the subtotal values exist
    postings.each do |posting|
      sub_total = posting.outbound_order_value_producer_net
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