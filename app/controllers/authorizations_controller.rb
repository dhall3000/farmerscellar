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
        flash.now[:success] = "Checkout successful"
        @tote_items = unauthorized_items_for(current_user).to_a

        @authorization.checkouts.order("checkouts.id").last.tote_items.where(state: ToteItem.states[:ADDED]).each do |tote_item|
          tote_item.transition(:customer_authorized)
        end

        #2016-10-15
        #next we display the 'checkout confirmation' page along with a list of the items just having gotten checked out. if we don't reload them
        #here their state will be ADDED when it should be AUTHORIZED. the only consequence of this i'm aware of is that if you have a partially filling
        #item when you expand the expansion row to get more info it reports "this item won't ship" when it should say "this item will only partially ship"
        @tote_items.each do |ti|
          ti.reload
        end

        @items_total_gross = get_gross_tote(@tote_items)
        @authorization.update(amount: @items_total_gross)
        current_user.send_authorization_receipt(@authorization)

        #20170404 sticking this in here but it will probably want to come out rather soonish. here's what's going on: ideally after every controller action but before render
        #i'd like to poll current_user.header_data_dirty and pull in fresh header data from the db and stick it in the session so the header displays accurately. alas,
        #there isn't a way to have stuff run on a filter after action before render. however, most of the time a tote item changes state the render happens as a result of a
        #redirect. in these cases the applicationcontroller's fetch_header_data before_action works just fine cause it pulls in fresh header data from db before the final render.
        #here, however, is an example of tote item state getting tweaked right before an immediate page render. so we have to hack things a bit to get proper header data displayed.
        #i'm about to overhaul order flow...my current plan is that after authorization i'll redirect them to the orders calendar. if that plan sticks we will be able to yank this code
        #cause the before action fetch_header_data will get called before the final calendar page render. actually, definitely remove it here to avoid double db data fetching.
        #and by the way, this code must come after the @rtauthorization.authorize_items_and_subscriptions and @rtauthorization.save lines just above. 
        current_user.reload
        fetch_header_data

      else
        flash.now[:danger] = "Checkout failed"
        AdminNotificationMailer.general_message("One time authorization failed", response.to_yaml).deliver_now
      end

    else
      AdminNotificationMailer.general_message("Checkout is nil", "admin, something went seriously wrong. The Checkout object is nil for the following authorization: #{response.to_yaml}").deliver_now      
      flash.now[:danger] = "Checkout failed"
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