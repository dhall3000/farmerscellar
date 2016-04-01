require 'test_helper'

class RtpurchaseTest < ActiveSupport::TestCase

	def setup
		@rtpurchase = Rtpurchase.new(
			success: true,
			message: "fakemessage",
			correlation_id: "fakecorrelation_id",
			ba_id: "fakeba_id",
			gross_amount: "10.00",
			fee_amount: "1.00",
			ack: "fakeack",
			error_code: "fakeerror_code"
			)
		@purchase_receivable = PurchaseReceivable.new(amount: 10, amount_purchased: 0, kind: 0)		
		@rtpurchase.purchase_receivables << @purchase_receivable
	end

	test "should save" do
		assert @rtpurchase.save
		assert @rtpurchase.valid?
	end

	test "should not save without message" do
		@rtpurchase.message = nil
		assert_not @rtpurchase.save
		assert_not @rtpurchase.valid?
	end

	test "should not save without correlation_id" do
		@rtpurchase.correlation_id = nil
		assert_not @rtpurchase.save
		assert_not @rtpurchase.valid?
	end

	test "should not save without at least one purchase_receivable" do
		@rtpurchase.purchase_receivables.delete(@purchase_receivable)
		assert_not @rtpurchase.save
		assert_not @rtpurchase.valid?
	end

end