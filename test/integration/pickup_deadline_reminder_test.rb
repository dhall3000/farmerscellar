require 'test_helper'
require 'integration_helper'

class PickupDeadlineReminderTest < IntegrationHelper

  test "product delivered on wednesday user picks up on thursday more product delivered on friday user does not pick up again user gets email" do
    function_one(user_has_prior_pickup = false)    
  end

  test "product delivered on wednesday user picks up on thursday more product delivered on friday user does not pick up again user gets email has prior pickup" do
    function_one(user_has_prior_pickup = true)
  end

  test "fc product delivered on wednesday user picks up on thursday user does not get email" do
    function_two(user_has_prior_pickup = false)
  end

  test "fc product delivered on wednesday user picks up on thursday user does not get email has prior pickup" do
    function_two(user_has_prior_pickup = true)
  end

  test "fc customer only product delivered on wednesday user never picks up gets email on following monday" do
    function_three(user_has_prior_pickup = false)
  end

  test "fc customer only product delivered on wednesday user never picks up gets email on following monday has prior pickup" do
    function_three(user_has_prior_pickup = true)
  end

  test "partner customer only product delivered on wednesday user never picks up gets email on following monday" do
    function_four(user_has_prior_pickup = false)
  end

  test "partner customer only product delivered on wednesday user never picks up gets email on following monday has prior pickup" do
    function_four(user_has_prior_pickup = true)
  end

  def function_one(user_has_prior_pickup)

    nuke_all_postings
    wednesday_posting = create_next_wednesday_posting
    friday_posting = create_following_friday_posting(wednesday_posting)

    #add some tote items to user tote
    bob = create_user("bob", "bob@b.com", 98033)
    quantity = 2
    ti1_bob = create_authorized_tote_item_for(bob, wednesday_posting, quantity)
    ti2_bob = create_authorized_tote_item_for(bob, friday_posting, quantity)

    expected_num_pickups = 0

    if user_has_prior_pickup
      do_pickup_last_wednesday(bob)
      expected_num_pickups += 1
    end

    transition_posting_to_commitment_zone(wednesday_posting)
    transition_posting_to_commitment_zone(friday_posting)

    fill_and_deliver(wednesday_posting, quantity_to_fill = quantity)    
    assert Time.zone.now.wednesday?

    #ok so user has a wednesday and friday delivery. travel to thursday and do a pickup.
    assert_equal expected_num_pickups, bob.pickups.count
    travel 1.day
    assert Time.zone.now.thursday?
    do_pickup_for(bob)
    assert_equal expected_num_pickups + 1, bob.reload.pickups.count

    fill_and_deliver(friday_posting.reload, quantity_to_fill = quantity)
    assert Time.zone.now.friday?

    #skip to pickup deadline warning time
    travel_to_warning_day_time
    do_hourly_tasks

    #verify pickup deadline warning email goes out
    assert_equal 1, ActionMailer::Base.deliveries.count
    pickup_deadline_warning = ActionMailer::Base.deliveries.first
    verify_pickup_deadline_reminder_email(pickup_deadline_warning, bob, tote_items = [ti2_bob], partner_deliveries = nil)    
    verify_pickup_deadline_reminder_does_not_go_out_next_week

    travel_back

  end

  def function_two(user_has_prior_pickup)

    nuke_all_postings
    posting1 = create_next_wednesday_posting

    #add some tote items to user tote
    bob = create_user("bob", "bob@b.com", 98033)
    quantity = 2
    ti1_bob = create_authorized_tote_item_for(bob, posting1, quantity)

    expected_num_pickups = 0

    if user_has_prior_pickup
      do_pickup_last_wednesday(bob)
      expected_num_pickups += 1
    end

    transition_posting_to_commitment_zone(posting1)
    fill_and_deliver(posting1, quantity_to_fill = quantity)

    assert_equal 1, ActionMailer::Base.deliveries.count
    bob_mail = ActionMailer::Base.deliveries.first    
    assert ti1_bob.reload.state?(:FILLED)
    verify_proper_delivery_notification_email(bob_mail, ti1_bob)

    #right now it should be wednesday (delivery day). travel to thursday
    travel 1.day
    #verify it's thursday
    assert Time.zone.now.thursday?
    do_pickup_for(bob)
    assert_equal expected_num_pickups + 1, bob.pickups.count

    #skip to pickup deadline warning time
    travel_to_warning_day_time
    do_hourly_tasks

    #verify no warning emails went out
    assert_equal 0, ActionMailer::Base.deliveries.count            
    verify_pickup_deadline_reminder_does_not_go_out_next_week

    travel_back

  end

  def function_three(user_has_prior_pickup)

    nuke_all_postings
    posting1 = create_next_wednesday_posting

    #add some tote items to user tote
    bob = create_user("bob", "bob@b.com", 98033)
    quantity = 2
    ti1_bob = create_authorized_tote_item_for(bob, posting1, quantity)

    expected_num_pickups = 0

    if user_has_prior_pickup
      do_pickup_last_wednesday(bob)
      expected_num_pickups += 1
    end

    assert_equal expected_num_pickups, bob.pickups.count

    transition_posting_to_commitment_zone(posting1)
    fill_and_deliver(posting1, quantity_to_fill = quantity)

    assert_equal 1, ActionMailer::Base.deliveries.count
    bob_mail = ActionMailer::Base.deliveries.first    
    assert ti1_bob.reload.state?(:FILLED)
    verify_proper_delivery_notification_email(bob_mail, ti1_bob)    

    travel_to_warning_day

    #travel to what should be 1 hour prior to deadline warnings going out
    travel_to Time.zone.now.midnight + (FOODCLEAROUTWARNINGDAYTIME[:hour] - 1).hours
    
    do_hourly_tasks
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel 1.hour
    #now it should be the top of the hour at which we should send food clearout deadline warning
    do_hourly_tasks

    #verify pickup deadline warning email goes out
    assert_equal 1, ActionMailer::Base.deliveries.count
    pickup_deadline_warning = ActionMailer::Base.deliveries.first
    verify_pickup_deadline_reminder_email(pickup_deadline_warning, bob, tote_items = [ti1_bob], partner_deliveries = nil)    
    verify_pickup_deadline_reminder_does_not_go_out_next_week

    travel_back

  end

  def function_four(user_has_prior_pickup)

    nuke_all_postings
    
    #create partner user
    jane = create_partner_user("jane", "jane@j.com")    

    expected_num_pickups = 0

    if user_has_prior_pickup
      do_pickup_last_wednesday(jane)
      expected_num_pickups += 1
    end

    #send azure standard delivery notification
    travel_to get_next_wednesday

    log_in_as(users(:a1))
    post partner_users_send_delivery_notification_path, params: {user_ids: [jane.id], partner_name: "Azure Standard"}

    #skip to pickup deadline warning time
    travel_to_warning_day_time
    do_hourly_tasks

    #verify pickup deadline warning email goes out
    assert_equal 1, ActionMailer::Base.deliveries.count            
    pickup_deadline_warning = ActionMailer::Base.deliveries.first
    verify_pickup_deadline_reminder_email(pickup_deadline_warning, jane, tote_items = nil, jane.partner_deliveries_at_dropsite)
    verify_pickup_deadline_reminder_does_not_go_out_next_week

    travel_back

  end

  def travel_to_warning_day_time
    travel_to_warning_day
    travel_to Time.zone.now.midnight + FOODCLEAROUTWARNINGDAYTIME[:hour].hours
  end

  def do_pickup_for(user)
    log_in_as(users(:dropsite1))
    post pickups_path, params: {pickup_code: user.pickup_code.code}
    get pickups_log_out_dropsite_user_path
    follow_redirect!
  end

  def verify_pickup_deadline_reminder_does_not_go_out_next_week
    #loop over the following week's deadline warning time
    travel 7.days
    do_hourly_tasks
    #verify deadline warning email does not go out
    assert_equal 0, ActionMailer::Base.deliveries.count    
  end

  def do_hourly_tasks
    ActionMailer::Base.deliveries.clear    
    RakeHelper.do_hourly_tasks
  end

  def create_partner_user(name, email)
    
    log_in_as users(:a1)
    post partner_users_create_path, params: {name: name, email: email, dropsite: Dropsite.first.id}
    jane = assigns(:user)

    return jane

  end

  def travel_to_warning_day
    warning_wday = FOODCLEAROUTWARNINGDAYTIME[:wday]
    while Time.zone.now.wday != warning_wday
      travel 1.day
    end
  end

  def create_following_friday_posting(wednesday_posting)

    delivery_date = wednesday_posting.delivery_date + 2.days
    commitment_zone_start = delivery_date - 2.days

    create_commission(wednesday_posting.user, products(:milk), units(:gallon), 0.05)
    posting = create_posting(wednesday_posting.user, 2.00, products(:milk), units(:gallon), delivery_date, commitment_zone_start, units_per_case = 1)

    return posting

  end

  def create_next_wednesday_posting

    #create a posting
    delivery_date = get_next_wednesday
    commitment_zone_start = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "Distributor Inc.")
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)

    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 farms")
    producer1.distributor = distributor
    producer1.save

    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1)

    return posting

  end

  def create_authorized_tote_item_for(user, posting, quantity)

    tote_item = create_tote_item(user, posting, quantity)
    create_one_time_authorization_for_customer(user)

    return tote_item

  end

  def transition_posting_to_commitment_zone(posting)
    travel_to posting.commitment_zone_start
    do_hourly_tasks
  end

  def fill_and_deliver(posting, quantity_to_fill)
    #make tote items get delivered
    travel_to posting.delivery_date + 12.hours
    fill_posting(posting.reload, quantity_to_fill)

    #verify delivery notifications go out
    ActionMailer::Base.deliveries.clear
    do_delivery
  end

  def do_pickup_last_wednesday(user)
    num_pickups = user.pickups.count
    last_wednesday = get_last_wednesday
    now = Time.zone.now
    travel_to last_wednesday

    #note: here we used to do this line of code:
    #do_pickup_for(user)
    #but we can't because we just added the security feature where user only has access to dropsite
    #if they got a delivery in the week they're trying to enter. so this hack doesn't work of
    #just backing up the clock and doing a pickup cause the code now accuratley senses there is
    #nothing in the dropsite for the user and bars access. so what we're now doing is hacking
    #the hack by just creating a pickup object back in time

    user.pickups.create    
    travel_to now
    assert_equal num_pickups + 1, user.reload.pickups.count
    
  end

end