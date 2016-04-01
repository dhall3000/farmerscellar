require 'test_helper'

class RtauthorizationTest < ActiveSupport::TestCase

	def setup
		@rtba = rtbas(:one)
		@rtauthorization = Rtauthorization.new(rtba_id: @rtba.id)
		@tote_item = tote_items(:c1apple)
		@rtauthorization.tote_items << @tote_item
	end

	test "should save" do
		assert @rtauthorization.save
		assert @rtauthorization.valid?
	end

	test "should not save without billing agreement reference" do
		@rtauthorization.rtba_id = nil
		assert_not @rtauthorization.save
		assert_not @rtauthorization.valid?
	end

	test "should not save without at least one tote item" do
		@rtauthorization.tote_items.delete(@tote_item)
		assert_not @rtauthorization.save
		assert_not @rtauthorization.valid?
	end

end
