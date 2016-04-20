class AuthorizationsController < ApplicationController
  def new

    @unauthorized_tote_items = current_user_current_unauthorized_tote_items
    
    if @unauthorized_tote_items.count < 1
      return
    end

  	# add express_token and payer_id columns to auth table
    if USEGATEWAY
      @authorization = Authorization.new(token: params[:token], payer_id: params[:PayerID])  	
    else
      @authorization = Authorization.new(token: params[:token], payer_id: ('a'..'z').to_a.shuffle[0..10].join)
    end
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
    @authorization.payment_date = DateTime.parse(response.params["payment_date"])
    @authorization.gross_amount = response.params["gross_amount"].to_f
    @authorization.gross_amount_currency_id = response.params["gross_amount_currency_id"]
    @authorization.payment_status = response.params["payment_status"]
    @authorization.pending_reason = response.params["pending_reason"]
    @authorization.ack = response.params["ack"]
    @authorization.response = response

    @authorization_succeeded = response.params["ack"] == "Success" && @authorization.gross_amount > 0

    checkout = Checkout.find_by(token: authorization_params[:token])
    if checkout != nil      
      @authorization.checkouts << checkout

      if @authorization_succeeded && @authorization.checkouts.last.tote_items.any?        
        flash.now[:success] = "Payment authorized!"
        @successfully_authorized_tote_items = current_user_current_unauthorized_tote_items.to_a
        @authorization.checkouts.last.tote_items.where(state: ToteItem.states[:ADDED]).update_all(state: ToteItem.states[:AUTHORIZED])        
      else
        flash.now[:danger] = "Payment not authorized."
      end

      @authorization.save

      #placing this here is a hack. it's more appropriate location woudl be in the if @authorization_succeeded... block
      #above. however, we're currently using the auth id as an order number displayed to the user in their email receipt
      #so if we send the email receipt before saving there is nil for the id so it shows an error to the user. eventually
      #we need to have some other number besides id displayed to the user for reference back to us in case of a problem.
      if @authorization_succeeded
        current_user.send_authorization_receipt(@authorization)        
      end
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