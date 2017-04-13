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
    #EDGE CASE: 'laszlo' is user id 37. not sure how this happened but he has two different rtba objects in the db with exact same info except primary id (9 and 10)
    #and created_at diffs by about 0.5 seconds. my guess is he double-clicked the authorize button before i had disable code on the button. anyway, the following line
    #used to be Rtba.find_by(token: token). but that query pulls up .first. if you go to method def get_authorized_subscription_objects_for(user) the top of the
    #method is rtba = user.get_active_rtba, whose implementation calls rtbas.order("rtbas.id").last. that doesn't work. they either need to both point at .first or both
    #point at .last
  	rtba = Rtba.where(token: token).last

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
  
  	flash[:success] = "Checkout successful"		
    @authorization_succeeded = true
    redirect_to tote_items_path(calendar: 1)

  end
end