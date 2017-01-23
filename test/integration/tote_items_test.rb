require 'integration_helper'

class ToteItemsTest < IntegrationHelper

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
    ti = create_tote_item2(bob, posting, quantity = 1)
    
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
    ti = create_tote_item2(bob, posting, quantity = 1)
    
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
    ti = create_tote_item2(bob, posting, quantity = 1, frequency = 1)
        
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
    ti = create_tote_item2(bob, posting, quantity = 1, frequency = 0, roll_until_filled = true)

  end

  def create_tote_item2(customer, posting, quantity, frequency = nil, roll_until_filled = nil)
 
    log_in_as(customer)
    assert is_logged_in?

    get postings_path
    assert_response :success
    assert_template 'postings/index'
    get posting_path(posting)
    assert_response :success
    assert_template 'postings/show'

    post tote_items_path, params: {posting_id: posting.id, quantity: quantity}
    tote_item = assigns(:tote_item)

    if posting.posting_recurrence.nil? || !posting.posting_recurrence.on
      assert_tote_item_added(tote_item)
      return
    end

    #now we know there's a posting recurrence so we should be on the 'how often?' page
    assert_response :success
    assert_template 'tote_items/how_often'
    assert_not tote_item

    posting_id = assigns(:posting_id)
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
      return
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

  end

  def assert_tote_item_added(tote_item)
    assert tote_item.valid?
    assert tote_item.id
    assert_response :redirect
    assert_redirected_to food_category_path_helper(tote_item.posting.product.food_category)    
    assert_equal flash[:success], "Tote item added"
  end

end