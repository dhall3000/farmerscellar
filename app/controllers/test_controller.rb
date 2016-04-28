class TestController < ApplicationController
	
	before_action :redirect_to_root_if_user_not_admin

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
