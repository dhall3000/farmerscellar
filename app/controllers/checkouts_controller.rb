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
        items: get_order_summary_details_for_paypal_display(@unauthorized_tote_items),
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

  private
    def get_order_summary_details_for_paypal_display(tote_items)
      summary_items = []

      if tote_items == nil || !tote_items.any?
        return summary_items
      end

      tote_items.each do |tote_item|
        summary_item = get_order_summary_item(tote_item)
        summary_items << summary_item
      end

      return summary_items
 
    end

    def get_order_summary_item(tote_item)
      summary_item = {}

      if tote_item == nil
        return summary_item
      end

      name = tote_item.posting.product.name
      description = "Producer - " + tote_item.posting.user.name

      summary_item[:name] = name
      summary_item[:description] = description
      summary_item[:quantity] = tote_item.quantity
      summary_item[:amount] = (tote_item.price).round(2) * 100

      return summary_item
      
    end
end

class FakeCheckoutResponse
  attr_reader :token
  def initialize
    @token = ('a'..'z').to_a.shuffle[0..10].join
  end
end