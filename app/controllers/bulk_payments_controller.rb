class BulkPaymentsController < ApplicationController
  def new
  	@unpaid_payment_payables = PaymentPayable.where(:amount_paid < :amount)
  	@grand_total_payout = 0

  	@total_payout_amount_by_producer_id = {}
  	@unpaid_payment_payable_ids = []

  	@unpaid_payment_payables.each do |p|
  	  @unpaid_payment_payable_ids << p.id
  	  producer = p.users.last
  	  if @total_payout_amount_by_producer_id[producer.id] == nil
  	  	@total_payout_amount_by_producer_id[producer.id] = 0  	    	  	
  	  end
  	  amount_unpaid_on_this_payment_payable = p.amount - p.amount_paid
  	  @total_payout_amount_by_producer_id[producer.id] += amount_unpaid_on_this_payment_payable
  	  @grand_total_payout += amount_unpaid_on_this_payment_payable
  	end

  end

  def create
  	total_payout_amount_by_producer_id = params[:total_payout_amount_by_producer_id]
  	unpaid_payment_payable_ids = params[:unpaid_payment_payable_ids]

  	@num_payees = total_payout_amount_by_producer_id.keys.count
  	@cumulative_total_payout = 0
  	total_payout_amount_by_producer_id.each do |producer_id, total_payout_amount|
  	  @cumulative_total_payout += total_payout_amount.to_f
  	end
  end
end
