require 'test_helper'
require 'integration_helper'

class PickupDeadlineReminderTest < IntegrationHelper

  def get_next_wednesday

    next_wednesday = Time.zone.now.midnight
    while !next_wednesday.wednesday?
      next_wednesday += 1.day
    end

    return next_wednesday

  end

  def travel_to_warning_day
    warning_wday = FOODCLEAROUTWARNINGDAYTIME[:wday]
    while Time.zone.now.wday != warning_wday
      travel 1.day
    end
  end

  test "fc customer only product delivered on wednesday user never picks up gets email on following monday" do

    nuke_all_postings

    #create a posting
    delivery_date = get_next_wednesday
    commitment_zone_start = delivery_date - 2.days

    distributor = create_producer("distributor", "distributor@d.com", "WA", 98033, "www.distributor.com", "Distributor Inc.")
    distributor.create_business_interface(name: "Distributor Inc.", order_email_accepted: true, order_email: distributor.email, paypal_accepted: true, paypal_email: distributor.email)

    producer1 = create_producer("producer1", "producer1@p.com", "WA", 98033, "www.producer1.com", "producer1 farms")
    producer1.distributor = distributor
    producer1.save

    create_commission(producer1, products(:apples), units(:pound), 0.05)
    posting1 = create_posting(producer1, 1.00, products(:apples), units(:pound), delivery_date, commitment_zone_start, units_per_case = 1)

    #add some tote items to user tote
    bob = create_user("bob", "bob@b.com", 98033)
    ti1_bob = add_tote_item(bob, posting1, 2)
    create_one_time_authorization_for_customer(bob)
    travel_to posting1.commitment_zone_start
    ActionMailer::Base.deliveries.clear
    RakeHelper.do_hourly_tasks

    #make tote items get delivered
    travel_to posting1.delivery_date + 12.hours
    fill_posting(posting1.reload, 2)

    #verify delivery notifications go out
    ActionMailer::Base.deliveries.clear
    do_delivery
    assert_equal 1, ActionMailer::Base.deliveries.count
    bob_mail = ActionMailer::Base.deliveries.first    
    assert ti1_bob.reload.state?(:FILLED)
    verify_proper_delivery_notification_email(bob_mail, ti1_bob)    

    travel_to_warning_day

    #travel to what should be 1 hour prior to deadline warnings going out
    travel_to Time.zone.now.midnight + (FOODCLEAROUTWARNINGDAYTIME[:hour] - 1).hours
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks
    assert_equal 0, ActionMailer::Base.deliveries.count

    travel 1.hour
    #now it should be the top of the hour at which we should send food clearout deadline warning
    RakeHelper.do_hourly_tasks

    #verify pickup deadline warning email goes out
    assert_equal 1, ActionMailer::Base.deliveries.count
    pickup_deadline_warning = ActionMailer::Base.deliveries.first
    verify_pickup_deadline_reminder_email(pickup_deadline_warning, bob, [ti1_bob])
    
    #loop over the following week's deadline warning time
    travel 7.days
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks
    #verify deadline warning email does not go out
    assert_equal 0, ActionMailer::Base.deliveries.count    

    travel_back

  end

  test "partner customer only product delivered on wednesday user never picks up gets email on following monday" do

    nuke_all_postings
    
    #create partner user
    dropsite = Dropsite.first
    log_in_as users(:a1)
    post partner_users_create_path, params: {name: "jane", email: "jane@j.com", dropsite: dropsite.id}
    jane = assigns(:user)

    #send azure standard delivery notification
    travel_to get_next_wednesday
    post partner_users_send_delivery_notification_path, params: {user_ids: [jane.id], partner_name: "Azure Standard"}

    #skip to pickup deadline warning time
    travel_to_warning_day
    travel_to Time.zone.now.midnight + FOODCLEAROUTWARNINGDAYTIME[:hour].hours

    #do hourly tasks
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
    RakeHelper.do_hourly_tasks

    #verify deadline warning email sent
    assert_equal 1, ActionMailer::Base.deliveries.count
            
    #verify pickup deadline warning email goes out

    if false
    
      pickup_deadline_warning = ActionMailer::Base.deliveries.first
      verify_pickup_deadline_reminder_email(pickup_deadline_warning, bob, [ti1_bob])
      
      #loop over the following week's deadline warning time
      travel 1.week
      ActionMailer::Base.deliveries.clear
      assert_equal 0, ActionMailer::Base.deliveries.count
      RakeHelper.do_hourly_tasks
      #verify deadline warning email does not go out
      assert_equal 0, ActionMailer::Base.deliveries.count    

    end

    travel_back

  end

end