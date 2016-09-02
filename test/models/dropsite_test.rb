require 'test_helper'

class DropsiteTest < ActiveSupport::TestCase

  def setup
    @dropsite = Dropsite.first
  end

  test "next food clearout should be 1 minute from now" do
    travel_to Time.zone.local(2016, 8, 29, 19, 59)
    assert_equal 1.minute, @dropsite.next_food_clearout - Time.zone.now    
    travel_back
  end
  
  test "next food clearout should be 1 week minus 1 minute from now" do
    travel_to Time.zone.local(2016, 8, 29, 20, 1)
    assert_equal (1.week - 1.minute), @dropsite.next_food_clearout - Time.zone.now    
    travel_back
  end
  
  test "next food clearout should be 6 days from now" do
    travel_to Time.zone.local(2016, 8, 30, 20, 0)
    assert_equal 6.days, @dropsite.next_food_clearout - Time.zone.now    
    travel_back
  end
  
  test "next food clearout should be 1 day from now" do
    travel_to Time.zone.local(2016, 8, 28, 20, 0)
    assert_equal 1.day, @dropsite.next_food_clearout - Time.zone.now    
    travel_back
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