require_relative '../../app/helpers/tote_items_helper'
require_relative 'junk_closet'

include ToteItemsHelper
include ActionView::Helpers::NumberHelper

class BulkPaymentProcessing

	def self.do_bulk_producer_payment
    
    puts "BulkPaymentProcessing.do_bulk_producer_payment start"

    if deliveries_remaining_this_week
      puts "BulkPaymentProcessing.do_bulk_producer_payment: there are still deliveries outstanding this week so we're not going to do a bulk payment today. quitting."
    else      
      values = bulk_payment_new
      values = bulk_payment_create(values)      
      email_report_to_admin(values[:bulk_payment], values[:payment_info_by_producer_id])
    end

    puts "BulkPaymentProcessing.do_bulk_producer_payment end"

	end

	def self.bulk_payment_new

    puts "BulkPaymentProcessing.bulk_payment_new start"

  	unpaid_payment_payables = PaymentPayable.where("amount_paid < amount")

  	if unpaid_payment_payables.count == 0
      puts "BulkPaymentProcessing.bulk_payment_new there are no unpaid PaymentPayables so quitting."
      puts "BulkPaymentProcessing.bulk_payment_new end"
  		return
  	end

  	grand_total_payout = 0
  	payment_info_by_producer_id = {}

  	unpaid_payment_payables.each do |p|
  	  producer = p.users.last
  	  if payment_info_by_producer_id[producer.id] == nil
  	  	payment_info_by_producer_id[producer.id] = {amount: 0, payment_payable_ids: []}
  	  end
  	  amount_unpaid_on_this_payment_payable = p.amount - p.amount_paid  	  
      payment_info_by_producer_id[producer.id][:amount] = (payment_info_by_producer_id[producer.id][:amount] + amount_unpaid_on_this_payment_payable).round(2)
  	  payment_info_by_producer_id[producer.id][:payment_payable_ids] << p.id
      grand_total_payout = (grand_total_payout + amount_unpaid_on_this_payment_payable).round(2)
  	end

    puts "BulkPaymentProcessing.bulk_payment_new end"

  	return {unpaid_payment_payables: unpaid_payment_payables, grand_total_payout: grand_total_payout, payment_info_by_producer_id: payment_info_by_producer_id}

	end

	def self.bulk_payment_create(params)

    puts "BulkPaymentProcessing.bulk_payment_create start"

    if params.nil? || params[:payment_info_by_producer_id].nil?
      puts "payment_info_by_producer_id is nil. quitting."
      puts "BulkPaymentProcessing.bulk_payment_create end"
      return {payment_info_by_producer_id: nil, messages: ["payment_info_by_producer_id is nil. We cannot proceed with this bulk payment. Please do not touch the system any further until you can report this to a developer."]}
    end

    payment_info_by_producer_id = params[:payment_info_by_producer_id]

    if payment_info_by_producer_id.is_a? String
      payment_info_by_producer_id = eval payment_info_by_producer_id
    end

  	num_payees = payment_info_by_producer_id.keys.count
  	cumulative_total_payout = 0
  	payment_info_by_producer_id.each do |producer_id, payment_info|
  	  cumulative_total_payout = (cumulative_total_payout + payment_info[:amount].to_f).round(2)
  	end

  	response = send_payments(payment_info_by_producer_id)
    payment_invoice_infos = send_payment_invoices(payment_info_by_producer_id)
  	
    puts "BulkPaymentProcessing.bulk_payment_create: returned from sending payments. now building a BulkPayment object to save to db."
	  #create a BulkPayment object
	  #create a Payment object for each payment in the BulkPayment
	  bulk_payment = BulkPayment.new(num_payees: payment_info_by_producer_id.keys.count, total_payments_amount: cumulative_total_payout)
	  payment_info_by_producer_id.each do |producer_id, payment_info|
	  	payment = Payment.new(amount: payment_info[:amount])  	  	
	  	payment_info[:payment_payable_ids].each do |payment_payable_id|
	  	  payment_payable = PaymentPayable.find(payment_payable_id.to_i)
        #TODO (Future):this isn't quite the right thing to do. we're unconditionally saying that every payment has been made when in fact it might not have
        #gone through successfully. the reason for this is because i need to move on since we're in early-stage biz dev
        #for now what i really want to make sure is that we're keeping all the information in case we get in to a snafu we can
        #back our way out manually. in the future we should make it so that if there's an error in payment in will not flatten the
        #payment below but rather leave it as is AND alert the admin that there was a payment problem. the details of how to do this are
        #that when errors come down they have a funky identifier like 'L_EMAILn' where 'n' is the integer id of exactly which (of the potentially many)
        #payments failed. so i'd have to write tedious code to correlate this funky id with the ids in my system. notgonnadoit right now.
        payment_payable.update(amount_paid: payment_payable.amount)
	  	  payment.payment_payables << payment_payable
	  	  bulk_payment.payment_payables << payment_payable
	  	end
	  	payment.save
	  end
    save_response(response, bulk_payment)
	  bulk_payment.save  	

    puts "BulkPaymentProcessing.bulk_payment_create end"

  	return {payment_invoice_infos: payment_invoice_infos, messages: [], payment_info_by_producer_id: payment_info_by_producer_id, num_payees: num_payees, cumulative_total_payout: cumulative_total_payout, bulk_payment: bulk_payment}

	end

	def self.test_masspay

    #here's a sample happy response: "TIMESTAMP=2015%2d08%2d22T00%3a59%3a05Z&CORRELATIONID=4ab512d716828&ACK=Success&VERSION=124%2e0&BUILD=000000"
    #here's a sample unhappy response: "TIMESTAMP=2011%2d11%2d15T20%3a27%3a02Z&CORRELATIONID=5be53331d9700&ACK=Failure&VERSION=78%2e0&BUILD=000000&L_ERRORCODE0=15005&L_SHORTMESSAGE0=Processor%20Decline&L_LONGMESSAGE0=This%20transaction%20cannot%20be%20processed%2e&L_SEVERITYCODE0=Error&L_ERRORPARAMID0=ProcessorResponse&L_ERRORPARAMVALUE0=0051&AMT=10%2e40&CURRENCYCODE=USD&AVSCODE=X&CVV2MATCH=M"

    #this line of code should remain checked in. only use for development and uncomment it to do so.
    return

    email = params[:email]
    amount = params[:amount].to_f
    payouts_params = get_payout_params([{email: email, amount: amount}])    
    response = send_paypal_masspay(PAYPALCREDENTIALS, payouts_params)
    save_response(response, nil)

	end

	private

    def self.email_report_to_admin(bulk_payment, payment_info_by_producer_id)

      puts "BulkPaymentProcessing.email_report_to_admin start"

      body_lines = []

      if !payment_info_by_producer_id.nil?

        payment_amount_sum = 0

        payment_info_by_producer_id.each do |producer_id, payment_info|
          producer = User.find(producer_id)
          body_lines << number_to_currency(payment_info[:amount]) + " sent to " + producer.farm_name + " via email address " + producer.email + "."
          payment_amount_sum = (payment_amount_sum + payment_info[:amount]).round(2)
        end

        body_lines << "The sum of these payments is " + number_to_currency(payment_amount_sum) + "."

      end

      if !bulk_payment.nil?
        body_lines << "BulkPayment id: " + bulk_payment.id.to_s + ". num_payees " + bulk_payment.num_payees.to_s + ". total_payments_amount " + number_to_currency(bulk_payment.total_payments_amount)
      end

      if body_lines.count > 0
        puts "BulkPaymentProcessing.email_report_to_admin: emailing BulkPayment report to admin"
        AdminNotificationMailer.general_message("BulkPayment report", "body empty", body_lines).deliver_now
      end      

      puts "BulkPaymentProcessing.email_report_to_admin end"

    end

    def self.deliveries_remaining_this_week

      last_day_of_this_week = Time.zone.today

      while last_day_of_this_week.wday != ENDOFWEEK
        last_day_of_this_week = last_day_of_this_week + 1.day
      end

      outstanding_deliveries_this_week = Posting.where("delivery_date > ? and delivery_date <= ?", Time.zone.today.midnight, last_day_of_this_week)
      
      return outstanding_deliveries_this_week.count > 0

    end

    #sample success response.body = "TIMESTAMP=2015%2d08%2d22T00%3a59%3a05Z&CORRELATIONID=4ab512d716828&ACK=Success&VERSION=124%2e0&BUILD=000000"
    #sample failure response.body = "TIMESTAMP=2011%2d11%2d15T20%3a27%3a02Z&CORRELATIONID=5be53331d9700&ACK=Failure&VERSION=78%2e0&BUILD=000000&L_ERRORCODE0=15005&L_SHORTMESSAGE0=Processor%20Decline&L_LONGMESSAGE0=This%20transaction%20cannot%20be%20processed%2e&L_SEVERITYCODE0=Error&L_ERRORPARAMID0=ProcessorResponse&L_ERRORPARAMVALUE0=0051&AMT=10%2e40&CURRENCYCODE=USD&AVSCODE=X&CVV2MATCH=M"
    def self.save_response(response, bulk_payment)

      if response.nil? || response.body.nil?
        return
      end

      masspay_response_name_value_pairs = get_masspay_response_name_value_pairs(response.body)

      if masspay_response_name_value_pairs.nil?
        return
      end

      common_responses_hash = get_common_responses_hash(masspay_response_name_value_pairs)
      error_responses_hash = get_error_responses_hash(masspay_response_name_value_pairs)

      if common_responses_hash.nil?
        return
      end

      correlation_id = common_responses_hash["CORRELATIONID"]

      if bulk_payment.nil?
        pp_mp_common = PpMpCommon.new(correlation_id: correlation_id, time_stamp: common_responses_hash["TIMESTAMP"], ack: common_responses_hash["ACK"], version: common_responses_hash["VERSION"], build: common_responses_hash["BUILD"])
        pp_mp_common.save

        if !error_responses_hash.nil?
          error_responses_hash.each do |name, value|
            PpMpError.create(correlation_id: correlation_id, name: name, value: value)
          end          
        end
      else
        bulk_payment.pp_mp_commons.build(correlation_id: correlation_id, time_stamp: common_responses_hash["TIMESTAMP"], ack: common_responses_hash["ACK"], version: common_responses_hash["VERSION"], build: common_responses_hash["BUILD"])

        if !error_responses_hash.nil?
          error_responses_hash.each do |name, value|
            bulk_payment.pp_mp_errors.build(correlation_id: correlation_id, name: name, value: value)
          end
        end
      end

    end

    #result looks like this: {"L_ERRORCODE0"=>"15005", "L_SHORTMESSAGE0"=>"Processor%20Decline", "L_LONGMESSAGE0"=>"This%20transaction%20cannot%20be%20processed%2e", "L_SEVERITYCODE0"=>"Error", "L_ERRORPARAMID0"=>"ProcessorResponse", "L_ERRORPARAMVALUE0"=>"0051", "AMT"=>"10%2e40", "CURRENCYCODE"=>"USD", "AVSCODE"=>"X", "CVV2MATCH"=>"M"}
    def self.get_error_responses_hash(masspay_response_name_value_pairs)
      error_responses_hash = {}

      if masspay_response_name_value_pairs.nil?
        return error_responses_hash
      end

      masspay_response_name_value_pairs.each do |nvp|

        keep_it = true

        case nvp[:name]
        when "ACK"
          keep_it = false
        when "CORRELATIONID"
          keep_it = false          
        when "TIMESTAMP"
          keep_it = false
        when "VERSION"
          keep_it = false
        when "BUILD"
          keep_it = false
        end

        if keep_it
          error_responses_hash[nvp[:name]] = nvp[:value]
        end

      end

      return error_responses_hash
    end

    #result looks like this: {"TIMESTAMP"=>"2011%2d11%2d15T20%3a27%3a02Z", "CORRELATIONID"=>"5be53331d9700", "ACK"=>"Failure", "VERSION"=>"78%2e0", "BUILD"=>"000000"}
    def self.get_common_responses_hash(masspay_response_name_value_pairs)

      common_responses_hash = {}

      if masspay_response_name_value_pairs.nil?
        return common_responses_hash
      end

      masspay_response_name_value_pairs.each do |nvp|

        keep_it = false

        case nvp[:name]
        when "ACK"
          keep_it = true
        when "CORRELATIONID"
          keep_it = true
        when "TIMESTAMP"
          keep_it = true
        when "VERSION"
          keep_it = true
        when "BUILD"
          keep_it = true
        end

        if keep_it
          common_responses_hash[nvp[:name]] = nvp[:value]
        end

      end

      return common_responses_hash

    end

    def self.get_masspay_response_name_value_pairs(response_body)

      if response_body.nil?
        return nil
      end

      nvps = response_body.split("&")
      nvp_hash_array = []

      nvps.each do |nvp|
        nvp_arr = nvp.split("=")
        nvp_hash_array << {name: nvp_arr[0], value: nvp_arr[1]}
      end

      return nvp_hash_array

    end

    def self.send_payments(payment_info_by_producer_id)

      puts "BulkPaymentProcessing.send_payments start"

      if !USEGATEWAY
        response = FakeMasspayResponse.new
        return response
      end

      email_amount_pairs = get_email_amount_pairs(payment_info_by_producer_id)
      payouts_params = get_payout_params(email_amount_pairs)
      response = send_paypal_masspay(PAYPALCREDENTIALS, payouts_params)

      puts "BulkPaymentProcessing.send_payments end"

      return response

    end

    def self.send_payment_invoices(payment_info_by_producer_id)

      payment_invoice_infos = []

      payment_info_by_producer_id.each do |producer_id, payment_info|

        producer = User.find(producer_id)
        total_amount = payment_info[:amount]
        payment_payable_ids = payment_info[:payment_payable_ids]
        posting_infos = get_posting_infos(payment_payable_ids)
        payment_invoice_infos << {total: total_amount, posting_infos: posting_infos}

        ProducerNotificationsMailer.payment_invoice(producer, total_amount, posting_infos).deliver_now
                
      end

      return payment_invoice_infos

    end

    def self.get_posting_infos(payment_payable_ids)
      posting_infos = {}

      payment_payable_ids.each do |payment_payable_id|

        pp = PaymentPayable.find(payment_payable_id)

        pp.tote_items.each do |tote_item|

          if !posting_infos.has_key?(tote_item.posting)
            posting_infos[tote_item.posting] = {unit_count: 0, unit_price: 0, sub_total: 0}
          end

          producer_net_item = get_producer_net_item(tote_item)

          posting_infos[tote_item.posting][:unit_count] += tote_item.quantity
          posting_infos[tote_item.posting][:sub_total] = (posting_infos[tote_item.posting][:sub_total] + producer_net_item).round(2)
          posting_infos[tote_item.posting][:unit_price] = (producer_net_item / tote_item.quantity).round(2)

        end

      end

      return posting_infos
      
    end

    def self.get_credentials_hash
      return PAYPALCREDENTIALS    
    end

    def self.get_payout_params(email_amount_pairs)
      payout_params = get_payout_params_common

      i = 0

      email_amount_pairs.each do |email_amount_pair|
        add_payment_to_payout_params(payout_params, email_amount_pair[:email], email_amount_pair[:amount].to_f, i)
        i += 1
      end

      return payout_params

    end

    def self.get_email_amount_pairs(payment_info_by_producer_id)

      email_amount_pairs = []

      payment_info_by_producer_id.each do |producer_id, payment_info|
        email_amount_pairs << {email: User.find(producer_id).email, amount: payment_info[:amount]}                                
      end

      return email_amount_pairs

    end

    #intent: the 'amount' param is expected to be a float
    #intent: email param should be an email address string
    def self.add_payment_to_payout_params(payouts_params, email, amount, sequence_num)
      if payouts_params.nil?
        payouts_params = {}
      end

      new_email_key = "L_EMAIL" + sequence_num.to_s        
      new_amount_key = "L_AMT" + sequence_num.to_s

      payouts_params[new_email_key] = email
      payouts_params[new_amount_key] = amount.round(2).to_s

    end

    def self.get_payout_params_common
      
      payouts_params =
      {
        "METHOD" => "MassPay",
        "CURRENCYCODE" => "USD",
        "RECEIVERTYPE" => "EmailAddress",
        "VERSION" => "124.0"
      }

      return payouts_params

    end

    def self.send_paypal_masspay(credentials, payouts_params)      

      puts "BulkPaymentProcessing.send_paypal_masspay start"

      response = nil

      if USEGATEWAY                
  	    url = URI.parse(PAYPALMASSPAYENDPOINT)
  	    http = Net::HTTP.new(url.host, url.port)
  	    http.use_ssl = true

        puts "BulkPaymentProcessing.send_paypal_masspay: sending paypal masspay. payouts_params (minus fc credentials): " + payouts_params.to_s        

  	    all_params = credentials.merge(payouts_params)
  	    stringified_params = all_params.collect { |tuple| "#{tuple.first}=#{CGI.escape(tuple.last)}" }.join("&")
  	    response = http.post("/nvp", stringified_params)
      else
      	response = true
      end

      puts "BulkPaymentProcessing.send_paypal_masspay end"
	    return response

    end

end

class FakeMasspayResponse
  attr_reader :body
  def initialize
    @body = "TIMESTAMP=2011%2d11%2d15T20%3a27%3a02Z&CORRELATIONID=5be53331d9700&ACK=Failure&VERSION=78%2e0&BUILD=000000&L_ERRORCODE0=15005&L_SHORTMESSAGE0=Processor%20Decline&L_LONGMESSAGE0=This%20transaction%20cannot%20be%20processed%2e&L_SEVERITYCODE0=Error&L_ERRORPARAMID0=ProcessorResponse&L_ERRORPARAMVALUE0=0051&AMT=10%2e40&CURRENCYCODE=USD&AVSCODE=X&CVV2MATCH=M"
  end
end