class AuthorizationsController < ApplicationController
  def new

    @unauthorized_tote_items = current_user_current_tote_items.where(status: ToteItem.states[:ADDED])
    
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
 	      
    checkout = Checkout.find_by(token: authorization_params[:token])
    if checkout != nil      
      @authorization.checkouts << checkout

      if @authorization.checkouts.last.tote_items.any?        
        @authorization.checkouts.last.tote_items.where(status: ToteItem.states[:ADDED]).update_all(status: ToteItem.states[:AUTHORIZED])
      end

      @authorization.save
    end    

    #TODO
  	#put success or failure code here
    
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
      "pending_reason": "FAKEREAON"
    }

    @params = @params.stringify_keys

  end

  private
    def random_string
      ('a'..'z').to_a.shuffle[0..10].join
    end
end