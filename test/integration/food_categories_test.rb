require 'integration_helper'

class FoodCategoriesTest < IntegrationHelper

  test "should return all childrens products" do
    
    nuke_all_postings
    nuke_all_users

    create_food_category("Shop", nil)

    shop = FoodCategory.find_by(name: "Shop")
    carrots = products(:carrots)
    carrots.update(food_category: shop)

    fruit = create_food_category("Fruit", shop)
    dairy = create_food_category("Dairy", shop)
    meat = create_food_category("Meat", shop)

    apples = products(:apples)
    apples.update(food_category: fruit)

    milk = products(:milk)
    milk.update(food_category: dairy)

    beef = products(:beef)
    beef.update(food_category: meat)

    products_under = shop.products_under
    assert_equal 1, products_under.where(name: "Carrots").count
    assert_equal 1, products_under.where(name: "Fuji Apples").count
    assert_equal 1, products_under.where(name: "Milk").count
    assert_equal 1, products_under.where(name: "Beef").count
    assert_equal 4, products_under.count

  end

  test "dev driver" do
    
    nuke_all_postings
    nuke_all_users

    create_food_category("Shop", nil)

    shop = FoodCategory.find_by(name: "Shop")

    fruit = create_food_category("Fruit", shop)
    dairy = create_food_category("Dairy", shop)
    meat = create_food_category("Meat", shop)

    apples = products(:apples)
    apples.update(food_category: fruit)

    milk = products(:milk)
    milk.update(food_category: dairy)

    beef = products(:beef)
    beef.update(food_category: meat)

    delivery_date = get_delivery_date(days_from_now = 3)

    posting_this = create_posting(farmer = nil, price = nil, product = products(:apples), unit = nil, delivery_date)
    posting_next = create_posting(farmer = nil, price = nil, product = products(:milk), unit = nil, delivery_date + 7.days)
    posting_future = create_posting(farmer = nil, price = nil, product = products(:beef), unit = nil, delivery_date + 14.days)

    bob = create_new_customer("bob", "bob@b.com")

    log_in_as(bob)
    get postings_path(food_category: "Meat")

  end

end