class AuthorizationsController < ApplicationController
  before_action :logged_in_user
  
  def new

    @tote_items = unauthorized_items_for(current_user)
    
    if @tote_items.count < 1
      return
    end

  	# add express_token and payer_id columns to auth table
    if USEGATEWAY
      @authorization = Authorization.new(token: params[:token], payer_id: params[:PayerID])  	
    else
      @authorization = Authorization.new(token: params[:token], payer_id: ('a'..'z').to_a.shuffle[0..10].join)
    end

    @authorization.amount = get_gross_tote(@tote_items)
    @items_total_gross = @authorization.amount

  end

  def create

  	@authorization = Authorization.new(authorization_params)
    @authorization.amount_purchased = 0
  	options = { ip:  request.remote_ip, token: @authorization.token, payer_id: @authorization.payer_id }  	

    if USEGATEWAY
      response = GATEWAY.authorize(@authorization.amount * 100, options)  
    else
      response = FakeAuthorizationResponse.new(@authorization.amount)
    end

    @authorization.correlation_id = response.params["correlation_id"]
    @authorization.transaction_id = response.params["transaction_id"]
    
    payment_date = response.params["payment_date"]
    if payment_date
      @authorization.payment_date = Time.zone.parse(payment_date)
    else
      #add a bogus date
      @authorization.payment_date = Time.zone.local(1900, 1, 1, 00, 00)
      AdminNotificationMailer.general_message("Authorization 'payment_date' param is nil", "admin, search for '#add a bogus date' in the code").deliver_now
    end
    
    @authorization.gross_amount = response.params["gross_amount"].to_f
    @authorization.gross_amount_currency_id = response.params["gross_amount_currency_id"]
    @authorization.payment_status = response.params["payment_status"]
    @authorization.pending_reason = response.params["pending_reason"]
    @authorization.ack = response.params["ack"]
    @authorization.response = response

    @authorization_succeeded = response.params["ack"] == "Success" && @authorization.gross_amount > 0
    if !@authorization_succeeded
      AdminNotificationMailer.general_message("One time authorization failed", response.to_yaml).deliver_now
    end

    checkout = Checkout.find_by(token: authorization_params[:token])

    if checkout

      @authorization.checkouts << checkout
      @authorization.save

      if @authorization_succeeded && @authorization.checkouts.order("checkouts.id").last.tote_items.any?        
        flash.now[:success] = "Payment authorized!"
        @tote_items = current_user_current_unauthorized_tote_items.to_a
        @authorization.checkouts.order("checkouts.id").last.tote_items.where(state: ToteItem.states[:ADDED]).each do |tote_item|
          tote_item.transition(:customer_authorized)
        end
        @items_total_gross = get_gross_tote(@tote_items)
        @authorization.update(amount: @items_total_gross)
        current_user.send_authorization_receipt(@authorization)
      else
        flash.now[:danger] = "Payment not authorized."
        AdminNotificationMailer.general_message("One time authorization failed", response.to_yaml).deliver_now
      end

    else
      AdminNotificationMailer.general_message("Checkout is nil", "admin, something went seriously wrong. The Checkout object is nil for the following authorization: #{response.to_yaml}").deliver_now      
      flash.now[:danger] = "Payment not authorized"
    end

  end

  private
    def authorization_params
    	params.require(:authorization).permit(:amount, :token, :payer_id)
    end

end

class FakeAuthorizationResponse
  attr_reader :params
  def initialize(amount)
    @params = {
      "correlation_id": random_string,
      "transaction_id": random_string,
      "payment_date": DateTime.now.to_s,
      "gross_amount": amount,
      "gross_amount_currency_id": "USD",
      "payment_status": "FAKEPENDING",
      "pending_reason": "FAKEREASON",
      "ack": "Success"
    }

    @params = @params.stringify_keys

  end

  private
    def random_string
      ('a'..'z').to_a.shuffle[0..10].join
    end
end