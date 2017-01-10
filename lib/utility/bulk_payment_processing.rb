require_relative '../../app/helpers/tote_items_helper'
require_relative 'junk_closet'

include ToteItemsHelper
include ActionView::Helpers::NumberHelper

class BulkPaymentProcessing

	def self.do_bulk_creditor_payment
    
    puts "BulkPaymentProcessing.do_bulk_creditor_payment start"

    if deliveries_remaining_this_week
      puts "BulkPaymentProcessing.do_bulk_creditor_payment: there are still deliveries outstanding this week so we're not going to do a bulk payment today. quitting."
    else

      positive_balanced_creditor_obligations = CreditorObligation.get_positive_balanced

      if positive_balanced_creditor_obligations.count == 0
        return
      end

      bp = BulkPayment.new(num_payees: positive_balanced_creditor_obligations.count, total_payments_amount: positive_balanced_creditor_obligations.sum(:balance).round(2))

      #hack: this object is gnarly and lame but scabbing this new code in to some legacy junk so that old tests will pass
      payment_info_by_creditor_id = {}

      positive_balanced_creditor_obligations.each do |co|
        
        payment = Payment.new(amount: co.balance)
        payment.save
        co.creditor_order.add_payment(payment)
        bp.payment_payables += co.reload.payment_payables
        
        ProducerNotificationsMailer.payment_invoice(co.creditor_order, payment).deliver_now

        if payment_info_by_creditor_id[co.creditor.id].nil?
          payment_info_by_creditor_id[co.creditor.id] = {amount: 0.0}
        end

        payment_info_by_creditor_id[co.creditor.id][:amount] = (payment_info_by_creditor_id[co.creditor.id][:amount] + payment.amount).round(2)

      end

      bp.save
      email_report_to_admin(bp, payment_info_by_creditor_id)

      payment_infos_by_payment_method = get_payment_infos_by_payment_method(payment_info_by_creditor_id)
      paypal_payment_info_by_creditor_id = payment_infos_by_payment_method[:paypal_payment_info_by_creditor_id]
      manual_payment_info_by_creditor_id = payment_infos_by_payment_method[:manual_payment_info_by_creditor_id]

      response = send_payments(paypal_payment_info_by_creditor_id)

      if response
        save_response(response, bp)
      end
      
      bp.save   

    end

    puts "BulkPaymentProcessing.do_bulk_creditor_payment end"

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

    def self.get_payment_infos_by_payment_method(payment_info_by_creditor_id)

      paypal_payment_info_by_creditor_id = {}
      manual_payment_info_by_creditor_id = {}

      payment_info_by_creditor_id.each do |creditor_id, payment_info|
        creditor = User.find(creditor_id)
        if creditor.nil?
          next
        end
        bi = creditor.get_business_interface
        if bi.payment_method?(:PAYPAL) #we eventually may want to change this to consider bi.payment_time in addition to bi.payment_method
          paypal_payment_info_by_creditor_id[creditor_id] = payment_info
        else
          manual_payment_info_by_creditor_id[creditor_id] = payment_info
        end
      end

      return {paypal_payment_info_by_creditor_id: paypal_payment_info_by_creditor_id, manual_payment_info_by_creditor_id: manual_payment_info_by_creditor_id}

    end

    def self.email_report_to_admin(bulk_payment, payment_info_by_creditor_id)

      puts "BulkPaymentProcessing.email_report_to_admin start"

      if payment_info_by_creditor_id.nil?
        puts "payment_info_by_creditor_id is nil"
        puts "BulkPaymentProcessing.email_report_to_admin end"
        return
      end

      payment_infos_by_payment_method = get_payment_infos_by_payment_method(payment_info_by_creditor_id)
      paypal_payment_info_by_creditor_id = payment_infos_by_payment_method[:paypal_payment_info_by_creditor_id]
      manual_payment_info_by_creditor_id = payment_infos_by_payment_method[:manual_payment_info_by_creditor_id]

      body_lines = []
      paypal_payment_amount_sum = 0      

      if paypal_payment_info_by_creditor_id.count > 0        

        body_lines << "PAYPAL PAYMENTS"

        paypal_payment_info_by_creditor_id.each do |creditor_id, payment_info|
          creditor = User.find(creditor_id)
          business_interface = creditor.get_business_interface
          body_lines << number_to_currency(payment_info[:amount]) + " sent to " + business_interface.name + " via email address " + business_interface.paypal_email + "."
          paypal_payment_amount_sum = (paypal_payment_amount_sum + payment_info[:amount]).round(2)
        end

        body_lines << "The sum of paypal payments is " + number_to_currency(paypal_payment_amount_sum) + "."

      end

      manual_payment_amount_sum = 0

      if manual_payment_info_by_creditor_id.count > 0        

        body_lines << "MANUAL PAYMENTS"
        
        manual_payment_info_by_creditor_id.each do |creditor_id, payment_info|
          creditor = User.find(creditor_id)
          body_lines << number_to_currency(payment_info[:amount]) + " to " + creditor.get_business_interface.name + "."
          manual_payment_amount_sum = (manual_payment_amount_sum + payment_info[:amount]).round(2)
        end

        body_lines << "The sum of manual payments is " + number_to_currency(manual_payment_amount_sum) + "."

      end

      if paypal_payment_amount_sum > 0 && manual_payment_amount_sum > 0
        total_sum = (paypal_payment_amount_sum + manual_payment_amount_sum).round(2)
        body_lines << "The sum of all payments is " + number_to_currency(total_sum) + "."
      end

      if bulk_payment.nil?
        body_lines << "bulk_payment is nil"
      else
        body_lines << "BulkPayment id: " + bulk_payment.id.to_s + ". num_payees " + bulk_payment.num_payees.to_s + "."
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

      outstanding_deliveries_this_week = Posting.where("delivery_date > ? and delivery_date <= ?", Time.zone.today.midnight, last_day_of_this_week.midnight)
      
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

    def self.send_payments(payment_info_by_creditor_id)

      puts "BulkPaymentProcessing.send_payments start"

      if payment_info_by_creditor_id.count < 1
        puts "not sending paypal payments because payment_info_by_creditor_id.count < 1"
        puts "BulkPaymentProcessing.send_payments end"
        return nil
      end

      email_amount_pairs = get_email_amount_pairs(payment_info_by_creditor_id)
      payouts_params = get_payout_params(email_amount_pairs)

      if USEGATEWAY
        response = send_paypal_masspay(PAYPALCREDENTIALS, payouts_params)
      else
        response = FakeMasspayResponse.new
      end      

      puts "BulkPaymentProcessing.send_payments end"

      return response

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

    def self.get_email_amount_pairs(payment_info_by_creditor_id)

      email_amount_pairs = []

      payment_info_by_creditor_id.each do |creditor_id, payment_info|
        creditor = User.find(creditor_id)
        business_interface = creditor.get_business_interface        
        email_amount_pairs << {email: business_interface.paypal_email, amount: payment_info[:amount]}                                
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