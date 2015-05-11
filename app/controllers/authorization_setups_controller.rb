class AuthorizationSetupsController < ApplicationController
  def create
  	@tote_items = current_user_current_tote_items

  	response = GATEWAY.setup_authorization(
      params[:amount].to_f * 100,
      ip: request.remote_ip,
      return_url: new_authorization_url,
      cancel_return_url: root_url,
      allow_guest_checkout: true
      )  	
  	
  	authorization_setup = AuthorizationSetup.new(token: response.token, amount: params[:amount].to_f, client_ip: request.remote_ip, response: response)

  	#TODO: before i save model instances should i check for .valid?

  	#save the AS to the db
  	if authorization_setup.save

  	  #stamp the AS/TI db with ids
  	  @tote_items.each do |tote_item|
  	    asti = AuthorizationSetupToteItem.new(authorization_setup_id: authorization_setup.id, tote_item_id: tote_item.id)
  	    if !asti.save
  	      #TODO: handle error case
  	    end
  	  end

  	  redirect_to GATEWAY.redirect_url_for(response.token)
  	else
  		#TODO: handle error case
  	end    
  end
end