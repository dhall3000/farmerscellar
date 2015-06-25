class BulkPaymentsController < ApplicationController
  def new
  	@unpaid_payment_payables = PaymentPayable.where(:amount_paid < :amount)
  	@grand_total_payout = 0

  	@payment_info_by_producer_id = {}

  	@unpaid_payment_payables.each do |p|
  	  producer = p.users.last
  	  if @payment_info_by_producer_id[producer.id] == nil
  	  	@payment_info_by_producer_id[producer.id] = {amount: 0, payment_payable_ids: []}
  	  end
  	  amount_unpaid_on_this_payment_payable = p.amount - p.amount_paid
  	  @payment_info_by_producer_id[producer.id][:amount] += amount_unpaid_on_this_payment_payable
  	  @payment_info_by_producer_id[producer.id][:payment_payable_ids] << p.id
  	  @grand_total_payout += amount_unpaid_on_this_payment_payable
  	end

  end

  def create
  	@payment_info_by_producer_id = params[:payment_info_by_producer_id]  	

  	@num_payees = @payment_info_by_producer_id.keys.count
  	@cumulative_total_payout = 0
  	@payment_info_by_producer_id.each do |producer_id, payment_info|
  	  @cumulative_total_payout += payment_info[:amount].to_f
  	end  	
  end
end
