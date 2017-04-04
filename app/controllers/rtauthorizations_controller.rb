class RtauthorizationsController < ApplicationController
  before_action :logged_in_user

  def new

  	#note: this is a bit of a misnomer. this #new action might make you think we're creating a new Rtauthorization. We're not. It's a hack
  	#for the uncommon event of creating a new Rtba object. I didn't want to create a separate controller just for one rtba action
  	#and that one (rare) action is related to and in the flow of rtauths so I just decided to throw this hack in here for now

  	if USEGATEWAY
  		details = GATEWAY.details_for(params[:token])
  	else
  		if params[:testparam_fail_fakedetailsfor]
  			details = RtauthorizationsHelper::FakeDetailsFor.new("failure")
  		else
  			details = RtauthorizationsHelper::FakeDetailsFor.new("success")
  		end  		
  	end  	

  	if details && details.success?
  		#display tote and 'agree & authorize' button
	  	@tote_items = unauthorized_items_for(current_user)      
      @subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true, kind = Subscription.kinds[:NORMAL])[:unauthorized]
  		@items_total_gross = get_gross_tote(@tote_items)
      @token = params[:token]
		else
			#flash danger 'please contact us, there was a problem'
			flash[:danger] = "There was a problem with Paypal. Please contact us if this continues."
			#email admin
			AdminNotificationMailer.general_message("User billing agreement signup failure!", details.to_yaml).deliver_now
			#redirect to the tote
			redirect_to tote_items_path
  	end

  end

  def create  	

  	token = params[:token]

  	#try to pull up an active ba
  	rtba = Rtba.find_by(token: token)

  	if rtba.nil?
  		#if we come from view/rtauth/new.html this means we're trying to set up a new billing agreement
			#this calls Paypal's CreateBillingAgreement API
			if USEGATEWAY
				ba = GATEWAY.store(token, {})
			else
				if params[:testparam_fail_fakestore]
					ba = RtauthorizationsHelper::FakeStore.new("failure")
				else
					ba = RtauthorizationsHelper::FakeStore.new("success")
				end				
			end
			
			if ba.success?				

				if params[:testparam_fail_rtba_creation]
					rtba = Rtba.new(token: token, user: current_user, active: true)					
				else
					rtba = Rtba.new(token: token, ba_id: ba.authorization, user: current_user, active: true)
				end
				
				if !rtba.valid?
					AdminNotificationMailer.general_message("Problem creating rtba!", rtba.errors.to_yaml).deliver_now
					flash[:danger] = "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us."
					redirect_to tote_items_path
					return
				end				

				rtba.save	

			else
				AdminNotificationMailer.general_message("Problem creating paypal billing agreement!", ba.to_yaml).deliver_now
				flash[:danger] = "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us."
				redirect_to tote_items_path
				return
			end
  	end

		if params[:testparam_fail_rtba_invalid]
			rtba.test_params = "failure"
		end					
  	
		#is ba legit?
		if !rtba.ba_valid?
			flash[:danger] = "The Billing Agreement we have on file is no longer valid. Please try to establish a new one by checking out again. If you continue to have problems please contact us."
			AdminNotificationMailer.general_message("Billing agreement invalid!", rtba.ba_id).deliver_now
			redirect_to tote_items_path
			return
		end

    #does this ba belong to current_user?
    if rtba.user.id != current_user.id
      #MAJOR PROBLEM!!
      #this is a serious problem. either there's a major problem with the code or someone's hacking, attempting to authorize payment off of someone
      #else's billing agreement
      body_lines = []
      body_lines << "rtba.user.id: #{rtba.user.id.to_s}"
      body_lines << "current_user.id: #{current_user.id.to_s}"
      AdminNotificationMailer.general_message("Billing agreement hack potential!", "fake body", body_lines).deliver_now      
      flash[:danger] = "Checkout failed. Please try again or contact us if this continues."
      redirect_to tote_items_path
      return
    end

    @all_subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true, kind = Subscription.kinds[:NORMAL])
    recurring_orders = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true)

    @tote_items = unauthorized_items_for(current_user)
    @subscriptions = @all_subscriptions[:unauthorized]

    @all_tote_items = all_items_for(current_user)
    @all_subscriptions = @all_subscriptions[:unauthorized] + @all_subscriptions[:authorized]

    @items_total_gross = get_gross_tote(@tote_items)
    
		#we have a legit billing agreement in place so now create a new authorization object and associate it with all appropriate other objects
		@rtauthorization = Rtauthorization.new(rtba: rtba)
	
    if !params[:testparam_fail_rtauthsave]
      @rtauthorization.authorize_items_and_subscriptions(@all_tote_items, recurring_orders[:unauthorized] + recurring_orders[:authorized])
    end

    #2016-10-15
    #next we display the 'checkout confirmation' page along with a list of the items just having gotten checked out. if we don't reload them
    #here their state will be ADDED when it should be AUTHORIZED. the only consequence of this i'm aware of is that if you have a partially filling
    #item when you expand the expansion row to get more info it reports "this item won't ship" when it should say "this item will only partially ship"
    @tote_items.each do |ti|
      ti.reload
    end

		if @rtauthorization.save
			UserMailer.authorization_receipt(current_user, @rtauthorization, @tote_items, @subscriptions).deliver_now			
		else
			AdminNotificationMailer.general_message("Problem saving Rtauthorization!", @rtauthorization.errors.to_yaml).deliver_now
		end

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
  	
  	flash.now[:success] = "Checkout successful"		
    @authorization_succeeded = true
    render 'authorizations/create'    

  end
end