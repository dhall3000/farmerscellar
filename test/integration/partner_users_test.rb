require 'test_helper'

class PartnerUsersTest < ActionDispatch::IntegrationTest

  test "new partner user should have good delivery notification and pickup experience" do

    #log in as admin
    log_in_as(users(:a1))    
    #create new partner user
    dropsite = Dropsite.first
    post partner_users_create_path, name: "jane", email: "jane@j.com", dropsite: dropsite.id
    assert_response :redirect
    assert_redirected_to partner_users_index_path
    user = assigns(:user)
    assert user.valid?
    assert user.id > 0
    assert user.pickup_code
    assert user.pickup_code.code.to_i > 0
    #send delivery notification
    ActionMailer::Base.deliveries.clear
    post partner_users_send_delivery_notification_path, user_ids: [user.id], partner_name: "Azure Standard"
    assert :redirected
    assert_redirected_to partner_users_index_path
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.first
    subject = "Azure Standard delivery notification & policy changes"
    assert_appropriate_email(mail, user.email, subject, "This email is your Farmer's Cellar delivery notification.")
    assert_appropriate_email(mail, user.email, subject, "Your pickup code is: #{user.pickup_code.code}")
    #log in as dropsite user
    log_in_as(users(:dropsite1))
    assert_response :redirect
    assert_redirected_to new_pickup_path
    #new user log in at the kiosk
    post pickups_path, pickup_code: user.pickup_code.code
    assert_response :success
    assert_template 'pickups/create'
    #open garage door
    post pickups_toggle_garage_door_path, pickup_code: user.pickup_code.code
    assert_response :success
    assert_template 'pickups/create'
    #close garage door
    post pickups_toggle_garage_door_path, pickup_code: user.pickup_code.code
    assert_response :success
    assert_template 'pickups/create'
    #log out of kiosk
    get new_pickup_path
    assert_response :success
    assert_template 'pickups/new'    

  end

end