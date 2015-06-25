class BulkPaymentsController < ApplicationController
  def new
  	@unpaid_payment_payables = PaymentPayable.where(:amount_paid < :amount)
  	@grand_total_payout = @unpaid_payment_payables.sum(:amount)

  	@total_payout_amount_by_producer_id = {}

  	@unpaid_payment_payables.each do |p|
  	  producer = p.users.last
  	  if @total_payout_amount_by_producer_id[producer.id] == nil
  	  	@total_payout_amount_by_producer_id[producer.id] = 0  	    	  	
  	  end
  	  @total_payout_amount_by_producer_id[producer.id] += p.amount - p.amount_paid
  	end

  end

  def create
  end
end
