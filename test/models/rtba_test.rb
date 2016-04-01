require 'test_helper'

class RtbaTest < ActiveSupport::TestCase

	def setup
		@user = users(:c1)
		@rtba = Rtba.new(token: "faketoken", ba_id: "fake_ba_id", user_id: @user.id, active: true)
	end

	test "should save" do
		assert @rtba.save
		assert @rtba.valid?
	end

	test "should not save without token" do
		@rtba.token = nil
		assert_not @rtba.save
		assert_not @rtba.valid?
	end

	test "should not save without ba_id" do
		@rtba.ba_id = nil
		assert_not @rtba.save
		assert_not @rtba.valid?		
	end

	test "should not save without user" do
		@rtba.user_id = nil
		assert_not @rtba.save
		assert_not @rtba.valid?		
	end

end
