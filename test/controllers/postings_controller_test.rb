require 'test_helper'
require 'utility/rake_helper'
require 'integration_helper'

class PostingsControllerTest < IntegrationHelper

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
      tote_item.transition(:order_cutoffed)    
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

  test "product id code should stick on posting creation" do
    
    pid_code = "davidproductcode"
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = pid_code)
    assert posting.valid?
    assert_equal pid_code, posting.product_id_code

  end

  test "producer net field should not show up on new if farmer is making the posting" do

    log_in_as(users(:f1))
    get new_posting_path
    assert_response :success
    assert_template 'postings/new'

    assert_select 'form label', {count: 0, text: "Producer net"}
    assert_select 'form input[type=number][name=producer_net]', 0

    producer = users(:f1)
    product = products(:apples)
    unit = units(:pound)

    old_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)

    post postings_path, params: {
      
      posting: {
        price: 10,
        user_id: producer.id,
        product_id: product.id,
        unit_id: unit.id,
        live: true,
        delivery_date: get_delivery_date(5),
        order_cutoff: get_delivery_date(3),
        description: "my description"
      }
    }

    posting = assigns(:posting)
    assert posting.valid?

    new_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)
    assert old_commission == new_commission

  end

  test "if producer somehow posts producer net during posting creation commission should not update" do

    log_in_as(users(:f1))
    get new_posting_path
    assert_response :success
    assert_template 'postings/new'

    assert_select 'form label', {count: 0, text: "Producer net"}
    assert_select 'form input[type=number][name=producer_net]', 0

    producer = users(:f1)
    product = products(:apples)
    unit = units(:pound)

    old_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)

    post postings_path, params: {
      producer_net: 9,      
      posting: {
        price: 10,
        user_id: producer.id,
        product_id: product.id,
        unit_id: unit.id,
        live: true,
        delivery_date: get_delivery_date(5),
        order_cutoff: get_delivery_date(3),
        description: "my description"
      }
    }

    posting = assigns(:posting)
    assert posting.valid?

    new_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)
    assert old_commission == new_commission

  end

  test "admin should be able to create a commission on the fly while spoofing farmer to create new posting" do

    log_in_as(users(:a1))
    post sessions_spoof_path, params: {email: "f1@f.com"}
    assert_equal "Now spoofing user f1@f.com", flash[:success]
    assert_redirected_to root_url

    get new_posting_path
    assert_response :success
    assert_template 'postings/new'

    assert_select 'form label', {count: 1, text: "Price per unit (producer net)"}
    assert_select 'form input[type=number][name=producer_net]', 1

    producer = users(:f1)
    product = products(:apples)
    unit = units(:pound)

    old_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)

    post postings_path, params: {
      producer_net: 9,
      posting: {
        price: 10,
        user_id: producer.id,
        product_id: product.id,
        unit_id: unit.id,
        live: true,
        delivery_date: get_delivery_date(5),
        order_cutoff: get_delivery_date(3),
        description: "my description"
      }
    }

    posting = assigns(:posting)
    assert posting.valid?

    new_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)
    assert old_commission != new_commission

  end

  test "should leave old commission in place when spoofing admin creates posting without specifying producer net" do

    log_in_as(users(:a1))
    post sessions_spoof_path, params: {email: "f1@f.com"}
    assert_equal "Now spoofing user f1@f.com", flash[:success]
    assert_redirected_to root_url

    get new_posting_path
    assert_response :success
    assert_template 'postings/new'

    assert_select 'form label', {count: 1, text: "Price per unit (producer net)"}
    assert_select 'form input[type=number][name=producer_net]', 1

    producer = users(:f1)
    product = products(:apples)
    unit = units(:pound)

    old_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)

    post postings_path, params: {
      producer_net: "", #if i just omit this var it evaluates to nil in the controller. but nil isn't what happens in the browser
      #what happens in the browser is as above...""
      posting: {
        price: 10,
        user_id: producer.id,
        product_id: product.id,
        unit_id: unit.id,
        live: true,
        delivery_date: get_delivery_date(5),
        order_cutoff: get_delivery_date(3),
        description: "my description"
      }
    }

    posting = assigns(:posting)
    assert posting.valid?

    new_commission = ProducerProductUnitCommission.get_current_commission_factor(producer, product, unit)
    assert old_commission == new_commission

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
    post postings_path, params: {posting: posting_params}
    posting = assigns(:posting)
    assert_not posting.valid?
    assert_not flash.empty?
    assert_equal "No commission is set for that product and unit. Please contact Farmer's Cellar to get a commission set.", flash.now[:danger]

  end

#NEW TESTS

  test "should fill all tote items in this posting" do
    fill(28)    
  end

  test "should fill only up to the amount of quantity that we received from producer" do
    #make this test to have COMMITTED toteitems of quantities like:
    #1,2,3,4,5,6,7 = 28
    #then recieve fill quantity 8 from producer so that the first 3 toteitems get fully filled
    #but the 4th toteitem (quantity 4) gets partially filled
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

  test "should do a partial fill" do
    #make this test to have COMMITTED toteitems of quantities like:
    #1,2,3,4,2,6,7 = 25
    #then recieve fill quantity 9 from producer so that items 1,2 & 3 get filled and the 4th item gets partially filled
    
    ######################setup######################
    posting = postings(:postingf5apples)
    ti = posting.tote_items.find_by(quantity: 5)
    ti.update(quantity: 2)
    ######################end setup######################

    fill_report = fill(9)

    assert_equal 0, fill_report[:quantity_remaining]
    assert_equal 1, fill_report[:partially_filled_tote_items].count

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
    travel_to posting.order_cutoff + 1
    RakeHelper.do_hourly_tasks
    posting.reload
    assert_equal Posting.states[:COMMITMENTZONE], posting.state

    travel_to posting.delivery_date + 1
    fill_report = fill_posting(posting, quantity)

    #verify success
    assert :success
    posting.reload
    #verify appropriate template displayed
    assert_template 'creditor_orders/show'

    #TODO: verify proper contents of template displayed
    #verify all tote items got filled
    filled_quantity = posting.tote_items.where(state: ToteItem.states[:FILLED]).sum(:quantity_filled)
    not_filled_quantity = posting.tote_items.where(state: [ToteItem.states[:NOTFILLED], ToteItem.states[:FILLED]]).sum(:quantity) - filled_quantity
    
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

    return fill_report

  end

  test "should fill" do
    
    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks
    
    #here is the non-failing "good" case
    travel_to posting.delivery_date + 1
    fill_report = fill_posting(posting, 28)
    assert :success
    
    assert_equal 28, fill_report[:quantity_filled]
    assert_equal 0, fill_report[:quantity_not_filled]
    assert_equal 0, fill_report[:quantity_remaining]

    travel_back

  end

  test "should not fill if quantity is nil" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        
    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks

    travel_to posting.delivery_date + 1
    #quantity is nil
    a1 = users(:a1)
    log_in_as(a1)
    assert is_logged_in?
    fills = get_creditor_order_fills_param(posting.id, nil)
    patch creditor_order_path(posting.creditor_order), params: {fills: fills}
    fill_report = assigns(:fill_report)
    assert :success
    assert fill_report.nil?

    travel_back    

  end

  test "should not fill if quantity is negative" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        
    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks

    travel_to posting.delivery_date + 1
    #quantity is negative
    fill_report = fill_posting(posting, -1)
    assert :success
    assert fill_report.nil?

    travel_back    

  end

  test "should not fill if creditor order does not exist" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        

    travel_to posting.delivery_date + 1
    #posting does not exist
    fake_posting_id = 987654
    a1 = users(:a1)
    log_in_as(a1)
    assert is_logged_in?
    fills = get_creditor_order_fills_param(fake_posting_id, 28)
    fake_creditor_order_id = 21975
    patch creditor_order_path(fake_creditor_order_id), params: {fills: fills}
    fill_report = assigns(:fill_report)

    assert :success
    assert fill_report.nil?
    
    travel_back    

  end

  test "should fill if posting has been ordered even if still before delivery date" do

    log_in_as(@admin)
    posting = postings(:postingf5apples)        
    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks

    travel_to posting.delivery_date - 1
    
    fill_report = fill_posting(posting, 28)
    assert :success

    assert_equal 28, fill_report[:quantity_filled]
    assert posting.reload.state?(:CLOSED)

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
    get new_posting_path
    assert_response :redirect
    assert_redirected_to login_url

    #now try logging in as customer. still should fail.
    log_in_as(@customer)
    get new_posting_path
    assert_response :redirect
    assert_redirected_to root_url
  end

  test "should copy posting on new" do
    log_in_as(@farmer)
    get new_posting_path(posting_id: @posting.id)
    assert_response :success
    assert_template 'postings/new'

  end

#INDEX TESTS
  test "should get index for users" do
    log_in_as(@customer)
    upload_file("noimage.jpg", "NoProductImage")
    successfully_get_index
    log_in_as(@farmer)
    successfully_get_index
  end

  test "should get index for admin" do
    log_in_as(@admin)
    upload_file("noimage.jpg", "NoProductImage")
    successfully_get_index
  end

  test "should get index for non users" do

    get postings_path
    assert :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_template 'static_pages/home'

    create_food_category_for_all_products_that_have_none
    root_category = FoodCategory.get_root_category
    assert root_category

    get postings_path(food_category: root_category.name)
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

    nuke_all_postings 
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
    nuke_all_postings
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
    nuke_all_postings
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
    get edit_posting_path(@posting)
    assert_not flash.empty?
    assert_redirected_to login_url    
  end

  test "should redirect edit when not logged in" do   
    get edit_posting_path(@posting)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect edit when logged in as customer" do
    log_in_as(@customer)
    get edit_posting_path(@posting)
    assert_redirected_to root_url    
  end

  test "should get edit when logged in as farmer" do
    log_in_as(@farmer)
    get edit_posting_path(@posting)
    posting = assigns(:posting)
    assert posting.valid?
    assert :success
    assert_template 'postings/edit'
  end

#UPDATE TESTS
  test "should redirect on update" do

    #first try updating as a not-logged-in user

    #update the posting with the new values
    patch posting_path(@posting, posting: {
      description: @posting.description + "new text",      
      price: @posting.price + 1.0,
      live: !(@posting.live)
    })

    assert_redirected_to login_url

    #now try updating as a logged in customer
    log_in_as(@customer)

    #update the posting with the new values
    patch posting_path(@posting, posting: {
      description: @posting.description + "new text",      
      price: @posting.price + 1.0,
      live: !(@posting.live)
    })

    assert_redirected_to root_url

  end

  test "should update attributes as farmer" do
    #allow: description_body, quantity available, price, live

    #we're going to take an existing posting, modify its values and update it
    #then we'll pull the new values up off the db and compare them to the old
    #values to verify change occurred

    log_in_as(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #update the posting with the new values
    patch posting_path(@posting, posting: {
      description: @posting.description + "new text",      
      price: @posting.price + 1.0,
      live: !(@posting.live)
    })

    #first make sure we were sent to the right place
    assert_redirected_to user_path(@farmer)    
    assert :success
    assert_not flash.empty?
    assert_equal flash[:success], "Posting updated!"    

    #now pull the new values up off the db for comparison
    @posting.reload
    
    #verify all the values have been changed
    assert @posting.description != posting_old.description    

    #assert @posting.price != posting_old.price
    #CHANGE: price can't be changed through the controller now
    assert_equal @posting.price, posting_old.price

    assert @posting.live != posting_old.live

  end

  test "should not update attributes as farmer" do
    #disallow: user_id, product_id, unit_category_id, unit_kind_id, delivery_date, order_cutoff, posting_recurrence values

    log_in_as(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #update the posting with the new values
    patch posting_path(@posting, posting: {
      user_id: @posting2.user_id,
      product_id: @posting2.product_id,
      unit_id: @posting2.unit_id,
      delivery_date: @posting2.delivery_date + 2.days,
      order_cutoff: @posting2.order_cutoff + 2.days      
    })

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
    assert @posting.order_cutoff == posting_old.order_cutoff    

  end

  test "should redirect update because invalid values" do
    #disallow: user_id, product_id, unit_category_id, unit_kind_id, delivery_date, order_cutoff, posting_recurrence values

    log_in_as(@farmer)
    get_access_for(@farmer)

    #copy the existing posting values so we can compare in the future to verify changes took effect
    posting_old = @posting.dup

    #set price to a negative value to trigger a fail
    patch posting_path(@posting, posting: {
      description: @posting.description + "new text",      
      price: -1.0,
      live: !(@posting.live)
    })

    #CHANGE: 2017-01-19
    #i made it so price can't be updated in the private postingscontroller params method
    #that makes it so that the change above passes just fine. you can pass a negative price in
    #all day long from the browser and the controller will just ignore it (or any other price)
    assert_response :redirect
    assert_redirected_to @farmer
    follow_redirect!
    assert_template 'users/show'
    return

    #now we should get sent back to the edit page with errors for user to see what went wrong
    assert :success
    assert_template 'postings/edit'
    assert_select 'div.alert.alert-danger', "The form contains 1 error."

  end

#SHOW TESTS
  test "should get show when not logged in" do
    get posting_path(@posting)
    assert :success
    assert_template 'postings/show'
    posting = assigns(:posting)
    assert posting.valid?
  end

  test "should get show" do
    log_in_as @customer
    get posting_path(@posting)
    assert :success
    assert_template 'postings/show'
    posting = assigns(:posting)
    assert posting.valid?
  end

#HELPER METHODS
  def get_postings_count
    
    log_in_as(@farmer)

    create_food_category_for_all_products_that_have_none

    root_category = FoodCategory.get_root_category

    get postings_path(food_category: root_category.name)
    this_weeks_postings = assigns(:this_weeks_postings)
    next_weeks_postings = assigns(:next_weeks_postings)
    future_postings = assigns(:future_postings)    
    
    postings_count = this_weeks_postings.count + next_weeks_postings.count + future_postings.count

    return postings_count

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
      live: true,
      delivery_date: delivery_date,
      product_id: @posting.product_id,
      unit_id: @posting.unit.id,
      order_cutoff: delivery_date - 2.days,
      units_per_case: 5
    }

    product = Product.find @posting.product_id
    assert product
    create_food_category_for_product_if_product_has_none(product)
    
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
    post postings_path, params: {posting: parms}
    posting = assigns(:posting)        
    assert posting.units_per_case > 1
    assert_not posting.nil?
    #the params were sent up to teh #create action with recurrence set to not repeat so we want to verify that .posting_recurrence is nil
    #because we don't want to create a db object for postings that don't repeat
    assert_not posting.posting_recurrence
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?    

    return posting    

  end

  test "successfully create posting with monthly recurrence" do
    successfully_create_posting_with_recurrence(monthly_posting_frequency = 5)
  end

  def successfully_create_posting_with_recurrence(posting_frequency = nil)

    if posting_frequency.nil?
      posting_frequency = 1
    end

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
    parms[:posting_recurrence] = {frequency: posting_frequency, on: true}
    post postings_path, params: {posting: parms}
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

    post postings_path, params: {posting: get_posting_params_hash}
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

    post postings_path, params: {posting: posting_hash}
    posting = assigns(:posting)
    assert_not posting.nil?
    assert posting.valid?, get_error_messages(posting)
    assert_redirected_to postings_path
    assert_not flash.empty?

    #ok, now we have to update this posting if we really want live unset
    patch posting_path(posting, posting: {live: false})
    posting = assigns(:posting)

    assert_not posting.live

    return posting
  end

  def get_new_successfully
    get new_posting_path
    assert_response :success
    assert_template 'postings/new'    
  end

  def successfully_get_index

    create_food_category_for_all_products_that_have_none

    root_category = FoodCategory.get_root_category
    assert root_category

    get postings_path(food_category: root_category.name)
    assert :success
    assert_template 'postings/index'

    #assert that there are at least several postings (this should be the case as long as there
    #are "at least several" postings in the posting.yml file)    
    assert_select "a.thumbnail img.img-responsive", minimum: 3

  end

  def fail_to_create(posting_params)
    post postings_path, params: {posting: posting_params}

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