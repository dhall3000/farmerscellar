class BulkPaymentsController < ApplicationController
  def new
  	@unpaid_payment_payables = PaymentPayable.where("amount_paid < amount")
  	@grand_total_payout = 0
  	@payment_info_by_producer_id = {}

  	@unpaid_payment_payables.each do |p|
  	  producer = p.users.last
  	  if @payment_info_by_producer_id[producer.id] == nil
  	  	@payment_info_by_producer_id[producer.id] = {amount: 0, payment_payable_ids: []}
  	  end
  	  amount_unpaid_on_this_payment_payable = p.amount - p.amount_paid  	  
      @payment_info_by_producer_id[producer.id][:amount] = (@payment_info_by_producer_id[producer.id][:amount] + amount_unpaid_on_this_payment_payable).round(2)
  	  @payment_info_by_producer_id[producer.id][:payment_payable_ids] << p.id
      @grand_total_payout = (@grand_total_payout + amount_unpaid_on_this_payment_payable).round(2)
  	end

  end

  def create    
  	@payment_info_by_producer_id = params[:payment_info_by_producer_id]  	

    if @payment_info_by_producer_id.is_a? String
      @payment_info_by_producer_id = eval @payment_info_by_producer_id
    end

  	@num_payees = @payment_info_by_producer_id.keys.count
  	@cumulative_total_payout = 0
  	@payment_info_by_producer_id.each do |producer_id, payment_info|
  	  @cumulative_total_payout += payment_info[:amount].to_f
  	end

  	response = send_payments(@payment_info_by_producer_id)
  	proceed = false

  	if USEGATEWAY
  	  proceed = true
  	else
  	  proceed = true
  	end

  	if proceed
  	  #create a BulkPayment object
  	  #create a Payment object for each payment in the BulkPayment
  	  bulk_payment = BulkPayment.new(num_payees: @payment_info_by_producer_id.keys.count, total_payments_amount: @cumulative_total_payout)
  	  @payment_info_by_producer_id.each do |producer_id, payment_info|
  	  	payment = Payment.new(amount: payment_info[:amount])  	  	
  	  	payment_info[:payment_payable_ids].each do |payment_payable_id|
  	  	  payment_payable = PaymentPayable.find(payment_payable_id.to_i)
          payment_payable.update(amount_paid: payment_payable.amount)
  	  	  payment.payment_payables << payment_payable
  	  	  bulk_payment.payment_payables << payment_payable
  	  	end
  	  	payment.save
  	  end
  	  bulk_payment.save
  	end  	

  end

  private

    def send_payments(payment_info_by_producer_id)
      payouts_params = get_payout_params(payment_info_by_producer_id)      
      send_paypal_masspay(PAYPALCREDENTIALS, payouts_params)
    end

    def get_credentials_hash
      return PAYPALCREDENTIALS    
    end

    def get_payout_params(payment_info_by_producer_id)
      payouts_params =
      {
      	"METHOD" => "MassPay",
    		"CURRENCYCODE" => "USD",
    		"RECEIVERTYPE" => "EmailAddress",
    		"VERSION" => "51.0"
    	}

  	  i = 0

  	  payment_info_by_producer_id.each do |producer_id, payment_info|
  	  	email = User.find(producer_id).email
  	  	new_email_key = "L_EMAIL" + i.to_s	

  	  	amount = payment_info[:amount].to_s
  	  	new_amount_key = "L_AMT" + i.to_s

  	  	payouts_params[new_email_key] = email
  	  	payouts_params[new_amount_key] = amount.to_f.round(2).to_s

  	  	i += 1
  	  end

  	  return payouts_params

    end

    def send_paypal_masspay(credentials, payouts_params)      

      response = nil

      if USEGATEWAY                
  	    url = URI.parse(PAYPALMASSPAYENDPOINT)
  	    http = Net::HTTP.new(url.host, url.port)
  	    http.use_ssl = true
  	    all_params = credentials.merge(payouts_params)
  	    stringified_params = all_params.collect { |tuple| "#{tuple.first}=#{CGI.escape(tuple.last)}" }.join("&")
  	    response = http.post("/nvp", stringified_params)
      else
      	response = true
      end

	  return response

    end
end
