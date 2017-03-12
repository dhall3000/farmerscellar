require 'test_helper'

class PickupsControllerTest < ActionDispatch::IntegrationTest

	def setup
		@customer = users(:c1)
		@admin = users(:a1)
		@farmer = users(:f1)
		@dropsite_user = users(:dropsite1)
	end

  test "should get new" do
  	log_in_as(@dropsite_user)
    get new_pickup_path
    assert_response :success
    assert_select 'form#pinForm', count: 1
  end

  test "should not get new when not logged in" do
    get new_pickup_path
    assert_response :redirect
    assert_select 'form#pinForm', count: 0
  end

  test "should not get new when logged in as customer" do
    log_in_as(@customer)
    get new_pickup_path
    assert_response :redirect
    assert_select 'form#pinForm', count: 0
  end

  test "should not get new when logged in as farmer" do
  	log_in_as(@farmer)
    get new_pickup_path
    assert_response :redirect
    assert_select 'form#pinForm', count: 0
  end

  test "should not get new when logged in as admin" do
    log_in_as(@admin)
    get new_pickup_path
    assert_response :redirect
    assert_select 'form#pinForm', count: 0
  end

  test "should create" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
  	c1 = users(:c1)
    hack_tote_item_and_clock(c1)
    post pickups_path, params: {pickup_code: c1.pickup_code.code}
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert pickup_code.valid?
    user = assigns(:user)
    assert user.valid?
    #a new pickup object should have been created as a result of this pickup action
    assert_equal pickups_count + 1, Pickup.count
    assert_equal c1.id, Pickup.all.last.user_id

    travel_back
    
  end

  def hack_tote_item_and_clock(user)
    #REMEMBER: travel_back when done using this method!

    #we have to hack a tote item. we have to make it be FILLED, then we have to make its posting
    #be delivered properly relative to the most recent dropsite clearout. otherwise the kiosk
    #login will fail
    ti = user.tote_items.first
    ti.update(state: ToteItem.states[:FILLED])

    if user.dropsite.nil?
      user.set_dropsite(Dropsite.first)
    end

    ti.posting.update(delivery_date: Time.zone.now.midnight, order_cutoff: Time.zone.now.midnight - 2.days)
    travel_to Time.zone.now.midnight + 12.hours

  end

  test "should create a single pickup row for full pickup process" do
    log_in_as(@dropsite_user)
    pickups_count = Pickup.count
    c1 = users(:c1)
    hack_tote_item_and_clock(c1)    
    post pickups_path, params: {pickup_code: c1.pickup_code.code}
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert pickup_code.valid?
    user = assigns(:user)
    assert user.valid?
    #a new pickup object should have been created as a result of this pickup action
    assert_equal pickups_count + 1, Pickup.count
    assert_equal c1.id, Pickup.all.last.user_id

    #ok, user logged in. now they open the garage door
    post pickups_toggle_garage_door_path, params: {pickup_code: c1.pickup_code.code}
    #and now they close the garage door
    post pickups_toggle_garage_door_path, params: {pickup_code: c1.pickup_code.code}

    #there shouldn't be any new pickup objects after cycling the garage door
    assert_equal pickups_count + 1, Pickup.count
    assert_equal c1.id, Pickup.all.last.user_id

    travel_back

  end

  test "should not create when invalid code submitted" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
    post pickups_path, params: {pickup_code: "12A45"}
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert_not pickup_code.valid?
    assert_not flash.empty?
    assert_equal "Invalid code entry", flash[:danger]
    assert_equal pickups_count, Pickup.count
  end

  test "should not create when non existent code submitted" do
  	log_in_as(@dropsite_user)
  	pickups_count = Pickup.count
    post pickups_path, params: {pickup_code: "1345"}
    assert_response :success
    pickup_code = assigns(:pickup_code)
    assert pickup_code.nil?
    assert_not flash.empty?
    assert_equal "Invalid code entry", flash[:danger]
    assert_equal pickups_count, Pickup.count
  end

end