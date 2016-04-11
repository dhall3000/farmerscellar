require 'test_helper'

class RtauthorizationTest < ActiveSupport::TestCase

	def setup
		@rtba = rtbas(:one)
		@rtauthorization = Rtauthorization.new(rtba_id: @rtba.id)
		@tote_item = tote_items(:c1apple)
		@rtauthorization.tote_items << @tote_item
	end

	test "authorized works right" do		
		assert @rtauthorization.save
		assert @rtauthorization.authorized?
		@rtba.update(active: false)
		@rtauthorization.reload
		assert_not @rtauthorization.authorized?
	end

	test "should deauthorize" do

		#move the ti state to auth'd
		@tote_item.update(status: ToteItem.states[:AUTHORIZED])
		#verify ti state is auth'd
		assert @tote_item.state?(:AUTHORIZED)		
		#call rtauth.deauth
		@rtauthorization.deauthorize
		#verify ti is deauth'd
		assert @tote_item.state?(:ADDED)		

	end

	test "should not deauthorize toteitems" do

		#move the ti state to committed
		@tote_item.update(status: ToteItem.states[:COMMITTED])
		#verify ti state is committed
		assert @tote_item.state?(:COMMITTED)		
		#call rtauth.deauth
		@rtauthorization.deauthorize
		#verify ti is not deauth'd
		assert_not @tote_item.state?(:ADDED)		

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
