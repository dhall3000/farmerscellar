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