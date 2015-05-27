class CheckoutsController < ApplicationController
  def create
  	@tote_items = current_user_current_tote_items

  	response = GATEWAY.setup_authorization(
      params[:amount].to_f * 100,
      ip: request.remote_ip,
      return_url: new_authorization_url,
      cancel_return_url: root_url,
      allow_guest_checkout: true
      )  	
  	
  	checkout = Checkout.new(token: response.token, amount: params[:amount].to_f, client_ip: request.remote_ip, response: response)

  	#TODO: before i save model instances should i check for .valid?

  	@tote_items.each do |tote_item|
  	  checkout.tote_items << tote_item
  	end

  	#save the AS to the db
  	if checkout.save
  	  redirect_to GATEWAY.redirect_url_for(response.token)
  	else
  		#TODO: handle error case
  	end    
  end
end
