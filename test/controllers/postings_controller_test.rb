require 'test_helper'

class PostingsControllerTest < ActionController::TestCase

  def setup
  	@farmer = users(:f1)    
    @customer = users(:c1)
    @admin = users(:a1)
  	@posting = postings(:postingf1apples)
    @posting2 = postings(:postingf2milk)

    #this posting is for the #fill functionality. the tote item states need to be in the following states
    #but if i initialize them to this in the yml file it breaks other tests so just setting the values here
    #so i don't have to fix lots of other tests
    posting = postings(:postingf5apples)
    
    posting.tote_items.each do |tote_item|
      tote_item.update(state: ToteItem.states[:ADDED])
      tote_item.transition(:customer_authorized)
      tote_item.transition(:commitment_zone_started)    
    end

    #now in order for these tests to come out right i have to set the quantities according to the id number progression
    i = 1
    posting.tote_items.order(:id).each do |tote_item|
      tote_item.update(quantity: i)      
      i = i + 1      
      #puts "#{tote_item.id.to_s}, quantity=#{tote_item.quantity.to_s}"
    end

    ti = posting.tote_items.find_by(quantity: 8)
    ti.update(state: ToteItem.states[:ADDED])

  end

  test "do not create if commission not set for producer product unit" do

    #this producer does not have a commission set for this product
    product = products(:milk)

    #log in
    log_in_as(@farmer)
    #make a posting that doesn't have price set
    posting_params = get_posting_params_hash
    posting_params[:product_id] = product.id
    commission = ProducerProductUnitCommission.where(user: @farmer, product: product, unit_id: posting_params[:unit_id])
    assert_equal 0, commission.count
    post :create, id: @farmer.id, posting: posting_params
    posting = assigns(:posting)
    assert_not posting.valid?
    assert_not flash.empty?
    assert_equal "No commission is set for that product and unit. Please contact Farmer's Cellar to get a commission set.", flash.now[:danger]

  end

  test "should display non closed postings for admin well after delivery day" do

    #assert this posting is OPEN
    assert_equal Posting.states[:OPEN], @posting.state

    @posting.tote_items.update_all(state: 2)
    travel_to @posting.delivery_date + 3.days

    #transitions the posting from OPEN to COMMITMENTZONE
    #this one is a bit artificial. this will happen automatically right at CZS
    #it should work the same here though
    RakeHelper.do_hourly_tasks
    @posting.reload
    assert_equal Posting.states[:COMMITMENTZONE], @posting.state

    #in the old manner this next call would have transitioned the posting to CLOSED because it was automatically, unconditionally, arbitrarily
    #transitioning to CLOSED at noon on delivery day
    #we're now no longer doing that
    RakeHelper.do_hourly_tasks
    @posting.reload
    assert_equal Posting.states[:COMMITMENTZONE], @posting.state

    admin = users(:a1)
    log_in_as(admin)
    get :index
    postings = assigns(:postings)

    #even though we're well past delivery day admin should still see the posting cause it wasn't closed
    assert_equal 1, postings.where(id: @posting.id).count
    
    travel_back

  end

#NEW TESTS

  test "should fill all tote items in this posting" do
    fill(28)    
  end

  test "should fill only up to the amount of quantity that we received from producer" do
    #make this test to have COMMITTED toteitems of quantities like:
    #1,2,3,4,5,6,7 = 28
    #then recieve fill quantity 8 from producer so that the first 3 toteitems get fully filled
    #but the 4th toteitem (quantity 4) doesn't get filled at all and there is quantity 2 left over
    fill(8)
  end

  test "should fill all tote items and have quantity left over" do
    #make this test to have COMMITTED toteitems of quantities like:
    #1,2,3,4,5,6,7 = 28
    #then recieve fill quantity 30 from producer so that all items get filled 
    #and verify quantity 2 remaining
    fill(30)
  end

  test "should handle zero quantity received" do
    fill(0)
  end

  test "should skip larger quantity tote items then fill a smaller quantity item" do
    #we only fill a tote item completely or not at all. so as we're running through the queue if we come across
    #a tote item we can't fill we shouldn't stop there. we should continue all the way through to the end of the
    #queue as long as we have 'quantity_remaining' looking for a tote item of smaller quantity that we can
    #completely fill. test that this works as expected.

    #make this test to have COMMITTED toteitems of quantities like:
    #1,2,3,4,2,6,7 = 25
    #then recieve fill quantity 9 from producer so that items 1,2 & 3 get filled, then 5 is skipped, 2 is filled with 1 leftover
    
    ######################setup######################
    posting = postings(:postingf5apples)
    ti = posting.tote_items.find_by(quantity: 5)
    ti.update(quantity: 2)
    ######################end setup######################

    fill(9)

  end

  def fill(quantity)
    log_in_as(@admin)

    posting = postings(:postingf5apples)
    committed_quantity = posting.tote_items.where(state: ToteItem.states[:COMMITTED]).sum(:quantity)

    if quantity == 9
      assert_equal 25, committed_quantity
    else
      assert_equal 28, committed_quantity
    end
    
    assert_equal 0, PurchaseReceivable.count
    assert_equal Posting.states[:OPEN], posting.state
    travel_to posting.commitment_zone_start + 1
    RakeHelper.do_hourly_tasks
    posting.reload
    assert_equal Posting.states[:COMMITMENTZONE], posting.state

    travel_to posting.delivery_date + 1

    post :fill, posting_id: posting.id, quantity: quantity
    #verify success
    assert :success
    posting = assigns(:posting)
    #verify appropriate template displayed
    assert_template 'postings/fill'
    #TODO: verify proper contents of template displayed
    #verify all tote items got filled
    filled_quantity = posting.tote_items.where(state: ToteItem.states[:FILLED]).sum(:quantity_filled)
    not_filled_quantity = posting.tote_items.where(state: [ToteItem.states[:NOTFILLED], ToteItem.states[:FILLED]]).sum(:quantity) - filled_quantity

    fill_report = assigns(:fill_report)

    if quantity == 8
      #if we were given quantity 8 by the producer, our first three tote items are for quantities 1,2 & 3
      #which is a total of 6. the 4th toteitem has quantity of 4
      #so the first three items should get fully filled and the last should be partially filled
      assert_equal 8, filled_quantity
      assert_equal 20, not_filled_quantity
      assert_equal 0, fill_report[:quantity_remaining]
      assert_equal 20, fill_report[:quantity_not_filled]
      assert_equal 1, fill_report[:partially_filled_tote_items].count
      #verify purchasereceivables got created appropriately? there should be 1 PR for each filled tote item
      assert_equal 4, PurchaseReceivable.count
    elsif quantity == 30      
      assert_equal committed_quantity, filled_quantity
      assert_equal 0, not_filled_quantity
      assert_equal 2, fill_report[:quantity_remaining]
      assert_equal 0, fill_report[:quantity_not_filled]
      #verify purchasereceivables got created appropriately? there should be 1 PR for each filled tote item
      assert_equal 7, PurchaseReceivable.count      
    elsif quantity == 28
      assert_equal committed_quantity, filled_quantity
      assert_equal 0, not_filled_quantity
      assert_equal 0, fill_report[:quantity_remaining]
      assert_equal 0, fill_report[:quantity_not_filled]
      #verify purchasereceivables got created appropriately? there should be 1 PR for each filled tote item
      assert_equal 7, PurchaseReceivable.count      
    elsif quantity == 0
      assert_equal 0, filled_quantity
      assert_equal committed_quantity, not_filled_quantity
      assert_equal 0, fill_report[:quantity_remaining]
      assert_equal committed_quantity, fill_report[:quantity_not_filled]
      #verify purchasereceivables got created appropriately? there should be 1 PR for each filled tote item
      assert_equal 0, PurchaseReceivable.count      
    elsif quantity == 9
      assert_equal 9, filled_quantity
      assert_equal 16, not_filled_quantity
      assert_equal 1, fill_report[:partially_filled_tote_items].count
      assert_equal 0, fill_report[:quantity_remaining]
      assert_equal 16, fill_report[:quantity_not_filled]

      #verify purchasereceivables got created appropriately? there should be 1 PR for each filled tote item
      assert_equal 4, PurchaseReceivable.count
    end            

    travel_back

    posting.reload
    assert_equal Posting.states[:CLOSED], posting.state    

  end

  test "should fill" do
    
    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    #here is the non-failing "good" case
    travel_to posting.delivery_date + 1
    post :fill, posting_id: posting.id, quantity: 28
    assert :success
    assert_template 'postings/fill'
    assert_select 'p', "quantity filled: 28", {count: 1}
    assert_select 'p', "quantity not filled: 0", {count: 1}
    assert_select 'p', "quantity remaining: 0", {count: 1}
    travel_back

  end

  test "should not fill if posting id is nil" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    #posting_id is nil
    travel_to posting.delivery_date + 1
    post :fill, posting_id: nil, quantity: 28
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}

    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "Something wasn't right. This condition failed: if !params[:posting_id].nil? && !params[:quantity].nil? && params[:quantity].to_i >= 0"
    travel_back    

  end

  test "should not fill if quantity is nil" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    travel_to posting.delivery_date + 1
    #quantity is nil
    post :fill, posting_id: posting.id, quantity: nil
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}
    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "Something wasn't right. This condition failed: if !params[:posting_id].nil? && !params[:quantity].nil? && params[:quantity].to_i >= 0"
    travel_back    

  end

  test "should not fill if quantity non number" do
    #TODO: we're not going to do this cause it's non obvious how to ensure the fill quantity param is a number
    return

    log_in_as(@admin)
    posting = postings(:postingf5apples)        
    
    travel_to posting.delivery_date + 1
    #quantity is not a number
    post :fill, posting_id: posting.id, quantity: 'abcd'
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}
    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "Something wasn't right. This condition failed: if !params[:posting_id].nil? && !params[:quantity].nil? && params[:quantity].to_i >= 0"
    travel_back    

  end

  test "should not fill if quantity is negative" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        
    
    travel_to posting.delivery_date + 1
    #quantity is negative
    post :fill, posting_id: posting.id, quantity: -1
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}
    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "Something wasn't right. This condition failed: if !params[:posting_id].nil? && !params[:quantity].nil? && params[:quantity].to_i >= 0"
    travel_back    

  end

  test "should not fill if posting does not exist" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    travel_to posting.delivery_date + 1
    #posting does not exist
    fake_posting_id = 987654
    post :fill, posting_id: fake_posting_id, quantity: 28
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}
    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "No posting was found with posting_id = #{fake_posting_id}"
    travel_back    

  end

  test "should not fill if posting has not been delivered yet" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    travel_to posting.delivery_date - 1
    post :fill, posting_id: posting.id, quantity: 28
    assert :success
    assert_template 'postings/fill'
    #assert fail message in body is there
    assert_select 'p', "@fill_report is nil"
    #assert report info not there
    assert_select 'p', {text: "quantity filled: 28", count: 0}
    #assert flash is present
    assert_not flash.now[:danger].empty?
    assert_equal flash.now[:danger], "The delivery date for this posting is #{@posting.delivery_date}"
    travel_back    

  end

  test "should get new for farmer and admin" do
    log_in_as(@farmer)
    get_new_successfully

    log_in_as(@admin)
    get_new_successfully    
  end

  test "should redirect on new for customer or non user" do
    #first try doing 'new' w/o logging in
    get :new
    assert_response :redirect
    assert_redirected_to login_url

    #now try logging in as customer. still should fail.
    log_in_as(@customer)
    get :new
    assert_response :redirect
    assert_redirected_to root_url
  end

  test "should copy posting on new" do
    log_in_as(@farmer)
    get :new, posting_id: @posting.id
    assert_response :success
    assert_template 'postings/new'

    #there should be a new posting form that's prepopulated with the old posting's values
    #do a spot check of one of the input fields to see if this is true
    assert_select '#posting_quantity_available' do
      assert_select "[value=?]", @posting.quantity_available.to_s
    end

  end

#INDEX TESTS
  test "should get index for users" do
    log_in_as(@customer)
    successfully_get_index

    log_in_as(@farmer)
    successfully_get_index
  end

  test "should get index for admin" do
    log_in_as(@admin)
    successfully_get_index

    #additionally, the admin postings index page should have a table with 'Edit' and 'Go!' columns
    assert_select 'tbody' do
      assert_select 'a[href=?]', edit_posting_path(@posting), {count: 1, text: "Edit"}
      assert_select 'form input[type=hidden][value=?]', @posting.id.to_s, {count: 1}
    end    

  end

  test "should get index for non users" do
    get :index
    assert :success
    assert_template 'postings/index'
  end

#CREATE TESTS
  test "successfully create a posting" do
    successfully_create_posting
  end

  test "gracefully fail to create posting if price not set" do
    #log in
    log_in_as(@farmer)
    #make a posting that doesn't have price set
    posting_params = get_posting_params_hash
    posting_params.delete(:price)
    fail_to_create(posting_params)

    #now let's try it again but with a positive recurrence set. should fail gracefully.
    posting_params[:posting_recurrence] = {frequency: PostingRecurrence.frequency[1][1], on: true}
    fail_to_create(posting_params)

  end

  test "newly created posting is posted when created properly with live set" do
 
    postings_count_prior = get_postings_count
    successfully_create_posting
    posting = assigns(:posting)
    assert_not posting.nil?    
    postings_count_post = get_postings_count
    assert postings_count_post > postings_count_prior, "the number of posts after successful post-creation was not greater than before successful post-creation"

  end

  #this new posting SHOULD show up in the My Postings section of the farmer's profile  
  test "newly created posting is not posted when created properly with live unset" do
    #this new posting should NOT show up in the shopping pages

    #we changed a feature so this is bogus. we now don't make the 'live' setting visible to user, assuming that if they're wanting to create a posting
    #that they also want it live. they can always go in and edit the posting if they really want it off
    next
    
    postings_count_prior = get_postings_count

    successfully_create_posting_with_live_unset
    posting = assigns(:posting)
    assert_not posting.nil?
    
    postings_count_post = get_postings_count
    assert postings_count_post == postings_count_prior, "the number of posts after successful non-live post-creation was not equal to the before successful non-live post-creation"
    
  end

#LIVE FEATURE TESTS  
  test "posted posting becomes unposted after unsetting live" do
    posting = successfully_create_posting
    postings_count_prior = get_postings_count
    live_prior = posting.live
    posting.live = false
    posting.save
    posting.reload
    live_post = posting.live
    assert live_prior != live_post
    postings_count_post = get_postings_count
    assert postings_count_post < postings_count_prior
  end

  test "unposted posting becomes posted after setting live" do
    posting = successfully_create_posting_with_live_unset
    postings_count_prior = get_postings_count
    live_prior = posting.live
    posting.live = true
    posting.save
    posting.reload
    live_post = posting.live
    assert live_prior != live_post
    postings_count_post = get_postings_count
    assert postings_count_post > postings_count_prior
  end

#RECURRENCE TESTS
  test "successfully create posting with recurrence set to not repeat" do
    successfully_create_posting_with_recurrence_set_to_not_repeat
  end

  test "successfully create posting with recurrence" do
    successfully_create_posting_with_recurrence
  end

#EDIT TESTS
  test "should get redirected if not logged in" do        
    get :edit, id: @posting
    assert_not flash.empty?
    assert_redirected_to login_url    
  end

  test "should redirect edit when not logged in" do   
    get :edit, id: @posting
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect edit when logged in as customer" do
    log_in_as(@customer)
    get :edit, id: @posting    
    assert_redirected_to root_url    
  end

  test "should get edit when logged in as farmer" do
    log_in_as(@farmer)
    get :edit, id: @posting
    posting = assigns(:posting)
    assert posting.valid?
    assert :success
    assert_template 'postings/edit'
  end

#UPDATE TESTS
  test "should redirect on update" do

    #first try updating as a not-logged-in user

    #update the posting with the new values
    post :update, id: @posting.id, posting: {
      description: @posting.description + "new text",
      quantity_available: @posting.quantity_available + 1,
      price: @posting.price + 1.0,
      live: !(@posting.live)
    }

    assert_redirected_to login_url

    #now try updating as a logged in customer
    log_in_as(@customer)

    #update the posting with the new values
    post :update, id: @posting.id, posting: {
      description: @posting.description + "new text",
      quantity_available: @posting.quantity_available + 1,
      price: @posting.price + 1.0,
      live: !(@posting.live)
    }

    assert_redirected_to root_url

  end

  test "should update attributes as farmer" do
    #allow: description, quantity available, price, live

    #we're going to take an existing posting, modify its values and update it
    #then we'll pull the new values up off the db and compare them to the old
    #values to verify change occurred

    log_in_as(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #update the posting with the new values
    post :update, id: @posting.id, posting: {
      description: @posting.description + "new text",
      quantity_available: @posting.quantity_available + 1,
      price: @posting.price + 1.0,
      live: !(@posting.live)
    }

    #first make sure we were sent to the right place
    assert_redirected_to user_path(@farmer)    
    assert :success
    assert_not flash.empty?
    assert_equal flash[:success], "Posting updated!"    

    #now pull the new values up off the db for comparison
    @posting.reload
    
    #verify all the values have been changed
    assert @posting.description != posting_old.description
    assert @posting.quantity_available != posting_old.quantity_available
    assert @posting.price != posting_old.price
    assert @posting.live != posting_old.live

  end

  test "should not update attributes as farmer" do
    #disallow: user_id, product_id, unit_category_id, unit_kind_id, delivery_date, commitment_zone_start, posting_recurrence values

    log_in_as(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #update the posting with the new values
    post :update, id: @posting.id, posting: {
      user_id: @posting2.user_id,
      product_id: @posting2.product_id,
      unit_id: @posting2.unit_id,
      delivery_date: @posting2.delivery_date + 2.days,
      commitment_zone_start: @posting2.commitment_zone_start + 2.days      
    }

    #first make sure we were sent to the right place
    assert_redirected_to user_path(@farmer)
    assert :success
    assert_not flash.empty?

    #now pull the new values up off the db for comparison
    @posting.reload

    #these should not be changed
    assert @posting.user_id == posting_old.user_id
    assert @posting.product_id == posting_old.product_id
    assert @posting.unit_id == posting_old.unit_id
    assert @posting.delivery_date == posting_old.delivery_date
    assert @posting.commitment_zone_start == posting_old.commitment_zone_start    

  end

  test "should redirect update because invalid values" do
    #disallow: user_id, product_id, unit_category_id, unit_kind_id, delivery_date, commitment_zone_start, posting_recurrence values

    log_in_as(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #set price to a negative value to trigger a fail
    post :update, id: @posting.id, posting: {
      description: @posting.description + "new text",
      quantity_available: @posting.quantity_available + 1,
      price: -1.0,
      live: !(@posting.live)
    }

    #now we should get sent back to the edit page with errors for user to see what went wrong
    assert :success
    assert_template 'postings/edit'
    assert_select 'div.alert.alert-danger', "The form contains 1 error."

  end

#SHOW TESTS
  test "should not get show" do
    get :show, id: @posting.id
    assert_redirected_to login_url
  end

  test "should get show" do
    log_in_as @customer
    get :show, id: @posting.id
    assert :success
    assert_template 'postings/show'
    posting = assigns(:posting)
    assert posting.valid?
  end

#HELPER METHODS
  def get_postings_count
    
    log_in_as(@farmer)
    get :index
    postings = assigns(:postings)        
    assert_not postings.nil?
    puts "postings.count = #{postings.count}"

    return postings.count

  end

  def get_posting_params_hash

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    posting = {
      user_id: @farmer.id,
      description: "descrip",
      price: 1,
      quantity_available: 10,
      live: true,
      delivery_date: delivery_date,
      product_id: @posting.product_id,
      unit_id: @posting.unit.id,
      commitment_zone_start: delivery_date - 2.days,
      units_per_case: 5,
      product_identifier: "XBZ-15"
    }

    return posting

  end

  def successfully_create_posting_with_recurrence_set_to_not_repeat
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    parms = get_posting_params_hash
    parms[:posting_recurrence] = {frequency: PostingRecurrence.frequency[0][1], on: false}
    post :create, id: @farmer.id, posting: parms
    posting = assigns(:posting)        
    assert posting.units_per_case > 1
    assert_not posting.product_identifier.empty?
    assert_not posting.nil?
    #the params were sent up to teh #create action with recurrence set to not repeat so we want to verify that .posting_recurrence is nil
    #because we don't want to create a db object for postings that don't repeat
    assert_not posting.posting_recurrence
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?    

    return posting    

  end

  def successfully_create_posting_with_recurrence
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    posting_recurrence_count = PostingRecurrence.count

    parms = get_posting_params_hash
    parms[:posting_recurrence] = {frequency: PostingRecurrence.frequency[1][1], on: true}
    post :create, id: @farmer.id, posting: parms
    posting = assigns(:posting)        
    assert_not posting.nil?    
    assert posting.posting_recurrence.valid?
    assert posting.valid?, get_error_messages(posting)
    #there should be more posting recurrences in the database now than thre was before this posting
    assert PostingRecurrence.count > posting_recurrence_count
    assert_redirected_to postings_path
    assert_not flash.empty?    

    return posting        
  end

  def successfully_create_posting
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    post :create, id: @farmer.id, posting: get_posting_params_hash
    posting = assigns(:posting)        
    assert_not posting.nil?
    #the params were sent up to teh #create action with no recurrence set so we want to verify that .posting_recurrence is nil
    #because we don't want to create a db object for postings that don't repeat
    assert_not posting.posting_recurrence
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?

    return posting

  end

  def successfully_create_posting_with_live_unset
    #log in
    log_in_as(@farmer)
    #go to post creation page
    #specify values, submit form

    posting_hash = get_posting_params_hash

    #actually, because of a feature change this now does nothing. on the next line when we 'post' the live var will get set to 'true'
    posting_hash[:live] = false

    post :create, id: @farmer.id, posting: posting_hash
    posting = assigns(:posting)
    assert_not posting.nil?
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?

    #ok, now we have to update this posting if we really want live unset
    patch :update, id: posting.id, posting: {live: false}
    posting = assigns(:posting)

    assert_not posting.live

    return posting
  end

  def get_new_successfully
    get :new
    assert_response :success
    assert_template 'postings/new'    
  end

  def successfully_get_index
    get :index
    assert :success
    assert_template 'postings/index'

    #assert that there are at least several postings (this should be the case as long as there
    #are "at least several" postings in the posting.yml file)
    assert_select 'tbody' do |elements|
      elements.each do |element|
        assert_select 'tr', minimum: 3
      end
    end
  end

  def fail_to_create(posting_params)
    post :create, id: @farmer.id, posting: posting_params

    #verify redirection    
    assert_template 'postings/new'
    #verify sad message
    posting = assigns(:posting)    
    assert_not posting.valid?, get_error_messages(posting)    
    #this is for the flash

    assert_select 'div.alert-danger', "The form contains 1 error."

    #this is for the specific errors that should be reported to the user
    assert_select 'div#error_explanation' do
      assert_select 'ul' do
        assert_select 'li', "Price must be greater than 0"        
      end
    end
  end

end