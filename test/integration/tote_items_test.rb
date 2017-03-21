require 'integration_helper'

class ToteItemsTest < IntegrationHelper

  test "tote items history should display" do

    #brand new user should see nothing in his history
    bob = create_user

    #shouldn't see history when not logged in
    get tote_items_path(history: true)
    assert_response :redirect
    assert_redirected_to login_path

    log_in_as(bob)
    assert_response :redirect
    assert_redirected_to tote_items_path(history: true)
    follow_redirect!    

    assert_template 'tote_items/history'
    assert_select 'p.text-center', "You have zero past tote items."    

    bob.set_dropsite(Dropsite.first)

    nuke_all_postings

    wednesday_next_week = get_next_wday_after(3, days_from_now = 7)
    posting1 = create_posting(producer = nil, price = 1.04, product = Product.create(name: "Product1"), unit = nil, delivery_date = wednesday_next_week, order_cutoff = wednesday_next_week - 1.day, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)
    posting2 = create_posting(posting1.user, price = 1.04,  product = Product.create(name: "Product2"), unit = nil, posting1.delivery_date, posting1.order_cutoff, units_per_case = nil, frequency = nil, order_minimum_producer_net = 0, product_id_code = nil, producer_net_unit = 1)

    ti_posting1 = create_tote_item(bob, posting1, quantity = 2)    
    ti_posting2 = create_tote_item(bob, posting2, quantity = 2)

    create_one_time_authorization_for_customer(bob)

    assert ti_posting1.reload.state?(:AUTHORIZED)
    assert ti_posting2.reload.state?(:AUTHORIZED)

    #move postings in to committment zone
    travel_to posting1.order_cutoff
    RakeHelper.do_hourly_tasks

    #fill the orders
    fully_fill_creditor_order(posting1.reload.creditor_order)

    #now travel 20 days in to the future and bob should have some history to loog at
    travel 20.days
    log_in_as bob
    get tote_items_path(history: true)
    assert_response :success
    assert_template 'tote_items/history'

    #we should have some thumbnails representing the historical tote items now. there should be two tote items and currently each tote item has two captions
    assert_select 'div.thumbnail div.caption', count: 4

    travel_back

  end

  test "user should be able to add a tote item to non recurring posting" do

    #we're wanting to test the path that does not have the "How Often?" page so we must have a posting
    #with no recurrence
    posting = create_posting
    shop = FoodCategory.create(name: "Shop")
    produce = FoodCategory.create(name: "Produce", parent: shop)
    assert produce.valid?
    posting.product.update(food_category: produce)

    assert posting.product.food_category
    assert_not posting.posting_recurrence

    bob = create_new_customer("bob", "bob@b.com")

    #add tote item
    ti = create_tote_item(bob, posting, quantity = 1)
    
  end

  test "user should be able to add a tote item to recurring posting" do

    #we're wanting to test the path that does not have the "How Often?" page so we must have a posting
    #with no recurrence
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1)
    shop = FoodCategory.create(name: "Shop")
    produce = FoodCategory.create(name: "Produce", parent: shop)
    assert produce.valid?
    posting.product.update(food_category: produce)

    assert posting.product.food_category
    assert posting.posting_recurrence

    bob = create_new_customer("bob", "bob@b.com")

    #add tote item
    ti = create_tote_item(bob, posting, quantity = 1)
    
  end

  test "user should be able to add a subscription to recurring posting" do

    #we're wanting to test the path that does not have the "How Often?" page so we must have a posting
    #with no recurrence
    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1)
    shop = FoodCategory.create(name: "Shop")
    produce = FoodCategory.create(name: "Produce", parent: shop)
    assert produce.valid?
    posting.product.update(food_category: produce)

    assert posting.product.food_category
    assert posting.posting_recurrence

    bob = create_new_customer("bob", "bob@b.com")

    #add tote item
    ti = create_tote_item(bob, posting, quantity = 1, frequency = 1)
        
  end

  test "user should be able to add a roll until filled order" do

    posting = create_posting(farmer = nil, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1)
    shop = FoodCategory.create(name: "Shop")
    produce = FoodCategory.create(name: "Produce", parent: shop)
    assert produce.valid?
    posting.product.update(food_category: produce)

    assert posting.product.food_category
    assert posting.posting_recurrence

    bob = create_new_customer("bob", "bob@b.com")

    #add tote item
    ti = create_tote_item(bob, posting, quantity = 1, frequency = 0, roll_until_filled = true)

  end

end