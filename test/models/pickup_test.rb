require 'test_helper'

class PickupTest < ActiveSupport::TestCase
  
  test "should not save without user" do
  	pickup = Pickup.new
  	assert_not pickup.valid?
  	assert_not pickup.save
  	assert_not pickup.valid?
  end

  test "should save with user" do
  	#save number of pickups user currently has
  	c = users(:c1)
  	num_pickups = c.pickups.count
  	#create a new pickup
  	c.pickups.create
  	#verify pickup is valid
  	c.pickups.last.valid?
  	#verify user now has 1 more pickup than previously
  	assert_equal num_pickups + 1, c.pickups.count
  end

end
