require 'integration_helper'

class PartnerUsersTest < IntegrationHelper

  test "new partner user should have good delivery notification and pickup experience" do

    #log in as admin
    log_in_as(users(:a1))    
    #create new partner user
    dropsite = Dropsite.first
    post partner_users_create_path, params: {name: "jane", email: "jane@j.com", dropsite: dropsite.id}
    assert_response :redirect
    assert_redirected_to partner_users_index_path
    user = assigns(:user)
    assert user.valid?
    assert user.id > 0
    assert user.pickup_code
    assert user.pickup_code.code.to_i > 0
    #send delivery notification
    ActionMailer::Base.deliveries.clear
    assert_equal 0, user.partner_deliveries.count
    post partner_users_send_delivery_notification_path, params: {user_ids: [user.id], partner_name: "Azure Standard"}
    assert_equal 1, user.partner_deliveries.count
    assert_equal "Azure Standard", user.partner_deliveries.first.partner
    assert :redirected
    assert_redirected_to partner_users_index_path
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.first
    subject = "Raw Milk $8.75 / gal & Azure Standard delivery notification"
    assert_appropriate_email(mail, user.email, subject, "Your pickup code is: #{user.pickup_code.code}")
    #log in as dropsite user
    log_in_as(users(:dropsite1))
    assert_response :redirect
    assert_redirected_to new_pickup_path
    #new user log in at the kiosk
    post pickups_path, params: {pickup_code: user.pickup_code.code}
    assert_response :success
    assert_template 'pickups/create'
    #open garage door
    post pickups_toggle_garage_door_path, params: {pickup_code: user.pickup_code.code}
    assert_response :success
    assert_template 'pickups/create'
    #close garage door
    post pickups_toggle_garage_door_path, params: {pickup_code: user.pickup_code.code}
    assert_response :success
    assert_template 'pickups/create'
    #log out of kiosk
    get new_pickup_path
    assert_response :success
    assert_template 'pickups/new'    

  end

end