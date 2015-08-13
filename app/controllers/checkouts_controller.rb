class CheckoutsController < ApplicationController
  def create
  	@tote_items = current_user_current_tote_items

    if @tote_items == nil || !@tote_items.any?
      flash[:danger] = "Can't checkout until you have some product in your tote"
      redirect_to postings_path
      return
    end

    if USEGATEWAY
      response = GATEWAY.setup_authorization(
        params[:amount].to_f * 100,
        ip: request.remote_ip,
        return_url: new_authorization_url,
        cancel_return_url: root_url,
        allow_guest_checkout: true
        )      
    else
      response = FakeCheckoutResponse.new
    end

    @checkout = Checkout.new(token: response.token, amount: params[:amount].to_f, client_ip: request.remote_ip, response: response)  	  	

  	#TODO: before i save model instances should i check for .valid?

  	@tote_items.each do |tote_item|
  	  @checkout.tote_items << tote_item
  	end

  	#save the AS to the db
  	if @checkout.save
  	  if USEGATEWAY
        redirect_to GATEWAY.redirect_url_for(response.token)
      else        
        #redirect_to new_authorization_path, token: response.token
        redirect_to(new_authorization_path(token: response.token))
      end
  	else
  		#TODO: handle error case
  	end    
  end
end

class FakeCheckoutResponse
  attr_reader :token
  def initialize
    @token = ('a'..'z').to_a.shuffle[0..10].join
  end
end