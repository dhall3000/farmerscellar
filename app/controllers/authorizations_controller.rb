class AuthorizationsController < ApplicationController
  def new
  	# add express_token and payer_id columns to auth table
    if USEGATEWAY
      @authorization = Authorization.new(token: params[:token], payer_id: params[:PayerID])  	
    else
      @authorization = Authorization.new(token: params[:token], payer_id: ('a'..'z').to_a.shuffle[0..10].join)
    end
  end

#response.params["timestamp"]

  def create
  	@authorization = Authorization.new(authorization_params)
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
 	      
    #tote_item -> as/ti -> as -> auth
    #TODO: error checking needs to happen here. what if there are no toteitems in the tote or no toteitems in the proper start state to make this transition?
    #@authorization.authorization_setup.tote_items.where(status: ToteItem.states[:ADDED]).update_all(status: ToteItem.states[:AUTHORIZED])
    checkout = Checkout.find_by(token: authorization_params[:token])
    if checkout != nil      
      @authorization.checkouts << checkout

      if @authorization.checkouts.last.tote_items.any?
        #TODO: is this a potential bug? what if the .where method returns a relation with zero records, will the .update_all crash?
        @authorization.checkouts.last.tote_items.where(status: ToteItem.states[:ADDED]).update_all(status: ToteItem.states[:AUTHORIZED])
      end

      #commenting out the state transition stuff...perhaps keeping state on a toteitem is unnecessary with the new db model layout as
      #i'll be able to go tote_item.checkouts.last.authorizations.any? and if that evaluates to true you know the tote_item is in the
      #authorized state.
      #authorization_setup.tote_items.where(status: ToteItem.states[:ADDED]).update_all(status: ToteItem.states[:AUTHORIZED])
      #@authorization.authorization_setup_id = authorization_setup.id
      @authorization.save
    end    

    #TODO
  	#stamp tote_items with @authorization.id
    #change state of tote_items to AUTHORIZED
  	#put success or failure code here
  	#how do i view authorizations on paypal.com? i'd like to be able to log in to my sandbox seller account and see some kind of list of auths to confirm i'm coding properly

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