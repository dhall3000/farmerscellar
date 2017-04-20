require 'integration_helper'

class PostingUiTest < IntegrationHelper

  test "pagination should work" do
    #as soon as i deployed pagination to production i started getting crashes. so this test is an attempt to repro the crashing prod environment. when postings thumbnail page had
    #enough postings to paginate it would crash when user would click on page 2. also, not sure if this is important (about to find out) but it was when the user had first selected
    #to display next week's postings, then next week's postings had multiple pages and the crash would happen when user would click on page 2.    

    nuke_all_postings
    assert_equal 0, Posting.count

    #set up a bunch of postings to replicate the situation
    start_of_week = get_next_wday_after(wday = STARTOFWEEK + 1, days_from_now = 1)
    next_week_delivery_date = start_of_week + 7.days
    travel_to start_of_week    

    producer = create_producer("Producer1", "producer1@p.com", distributor = nil, order_min = 0, create_default_business_interface = true)
    count = 0
    num_pages = 3
    num_postings = POSTINGSPERPAGE * num_pages
    posting = nil

    num_postings.times do
      posting = create_posting(producer, price = nil, product = Product.create(name: "Product#{count.to_s}"), unit = nil, next_week_delivery_date, order_cutoff = next_week_delivery_date - 2.days, units_per_case = nil, frequency = 1)
      count += 1
    end

    assert_equal num_postings, Posting.count

    #create new customer, log customer in
    bob = create_new_customer
    log_in_as bob
    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_template '/'

    food_category = posting.product.food_category.name

    #new customer browses to the postings page
    get postings_path(food_category: food_category)
    assert_response :success
    assert_template 'postings/index'

    #controller should have queried up the correct number of postings
    next_weeks_postings = assigns(:next_weeks_postings)
    assert_equal num_postings, next_weeks_postings.count

    #there should be one pagination page link for each of the pages we created
    num_pages.times do |i|
      assert_select 'div.pagination li a[href=?]', postings_path(food_category: food_category, next_week: (i + 1).to_s)
    end

    #the prod crash was happening when user clicked on page 2
    assert num_pages > 1
    get postings_path(food_category: food_category, next_week: "2")
    assert_response :success
    assert_template 'postings/index'
    
  end

end