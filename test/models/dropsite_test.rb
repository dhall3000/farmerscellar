require 'test_helper'

class DropsiteTest < ActiveSupport::TestCase

  def setup
    @dropsite = Dropsite.first
  end

  test "last clearout should be 1 minute ago" do    
    user_pickup_time = Time.zone.local(2016, 8, 8, 20, 1)
    travel_to user_pickup_time
    assert_equal 1.minute, Time.zone.now - @dropsite.last_food_clearout    
    travel_back
  end

  test "last clearout should be 6 days 23 hours 59 minutes ago" do
    user_pickup_time = Time.zone.local(2016, 8, 8, 19, 59)
    travel_to user_pickup_time
    assert_equal 604740, Time.zone.now - @dropsite.last_food_clearout    
    travel_back
  end

  test "last clearout should be 23 hours ago" do
    user_pickup_time = Time.zone.local(2016, 8, 9, 19, 0)
    travel_to user_pickup_time
    assert_equal 82800, Time.zone.now - @dropsite.last_food_clearout    
    travel_back
  end

  test "last clearout should be 25 hours ago" do
    user_pickup_time = Time.zone.local(2016, 8, 9, 21, 0)
    travel_to user_pickup_time
    assert_equal 90000, Time.zone.now - @dropsite.last_food_clearout    
    travel_back
  end

  test "last clearout should be 6 days ago" do
    user_pickup_time = Time.zone.local(2016, 8, 7, 20, 0)
    travel_to user_pickup_time
    assert_equal 518400, Time.zone.now - @dropsite.last_food_clearout    
    travel_back
  end

end