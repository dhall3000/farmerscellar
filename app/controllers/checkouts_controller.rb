class CheckoutsController < ApplicationController
  def create
  	@unauthorized_tote_items = current_user_current_unauthorized_tote_items

    if @unauthorized_tote_items == nil || !@unauthorized_tote_items.any?
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

  	@unauthorized_tote_items.each do |unauthorized_tote_item|
  	  @checkout.tote_items << unauthorized_tote_item
  	end

  	#save the AS to the db
  	if @checkout.save
  	  if USEGATEWAY
        redirect_to GATEWAY.redirect_url_for(response.token)
      else                
        redirect_to(new_authorization_path(token: response.token))
      end
  	else
      flash[:danger] = "Payment checkout error."
  	end    
  end
end

class FakeCheckoutResponse
  attr_reader :token
  def initialize
    @token = ('a'..'z').to_a.shuffle[0..10].join
  end
end