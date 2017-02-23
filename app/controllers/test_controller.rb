require 'memory_profiler'

class TestController < ApplicationController
	
	before_action :redirect_to_root_if_user_not_admin

  def memory_profiler

    if params[:start]
      flash[:success] = "MemoryProfiler started"
      MemoryProfiler.start
    elsif params[:stop]

      @report = MemoryProfiler.stop
      if @report
        flash[:success] = "MemoryProfiler stopped"
        @report.pretty_print
      else
        flash[:danger] = "MemoryProfiler report was nil"
      end
      
    end

    redirect_to root_path

  end

  def send_email

    to = params[:to]
    body = params[:body]

    AdminNotificationMailer.email_test(to, body).deliver_now

    flash[:success] = "Test email sent to #{to}"
    redirect_to root_path

  end

  def garage_door

    #http://10.0.0.19:1984/client?command=door2

    #uri = URI.parse("http://www.google.com/")

    #uri = URI.parse("http://10.0.0.19:1984/client?command=door2")
    #response = Net::HTTP.get_response(uri)

    #uri = URI.parse(request.ip)
    #response = Net::HTTP.get_response(uri, "/client?command=door2", 1984)

    #url = "http://50.46.117.254:1984/client?command=door2"    

    url =  "http://#{request.ip}:1984/client?command=door2"
    #url = "http://10.0.0.1:1984/client?command=door2"
    uri = URI(url)

    flash[:success] =  url

    response = Net::HTTP.get(uri)


#debugger

    #http://ruby-doc.org/stdlib-2.3.1/libdoc/net/http/rdoc/Net/HTTP.html
    #http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
    #send_paypal_masspay(credentials, payouts_params)

    redirect_to test_page_path

  end

  def checkout

  	response = GATEWAY.setup_authorization(
  		params[:amount].to_f * 100,
  		ip: request.remote_ip,
  		return_url: test_authorize_url,
  		cancel_return_url: test_page_url,
  		allow_guest_checkout: true
  		)      

		PAYPALDATASTORE[:token] = response.token
		PAYPALDATASTORE[:amount] = params[:amount].to_f

    puts "-------------checkout-------------"
    puts "PAYPALDATASTORE[:token] = #{PAYPALDATASTORE[:token]}"
    puts "PAYPALDATASTORE[:amount] = #{PAYPALDATASTORE[:amount]}"
    puts "response = #{response.to_yaml}"

		redirect_to GATEWAY.redirect_url_for(response.token)

  end

  def authorize

  	options = { ip:  request.remote_ip, token: PAYPALDATASTORE[:token], payer_id: params[:PayerID] }
  	response = GATEWAY.authorize(PAYPALDATASTORE[:amount] * 100, options)  
  	PAYPALDATASTORE[:transaction_id] = response.params["transaction_id"]

    puts "-------------authorize-------------"
    puts "PAYPALDATASTORE[:transaction_id] = #{PAYPALDATASTORE[:transaction_id]}"
    puts "response = #{response.to_yaml}"

	  render 'test/capture'

  end

  def capture

  	amount = params[:amount].to_f * 100
  	response = GATEWAY.capture(amount, PAYPALDATASTORE[:transaction_id], complete_type: "NotComplete")
  	PAYPALDATASTORE[:capture_response] = response

    puts "-------------authorize-------------"
    puts "response = #{response.to_yaml}"

  end

end
