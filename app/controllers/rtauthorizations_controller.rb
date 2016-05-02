class RtauthorizationsController < ApplicationController
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
	  	@tote_items_authorizable = current_user_current_unauthorized_tote_items	  	
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
					flash.now[:danger] = "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us."
					redirect_to tote_items_path
					return
				end				

				rtba.save	

			else
				AdminNotificationMailer.general_message("Problem creating paypal billing agreement!", ba.to_yaml).deliver_now
				flash.now[:danger] = "Couldn't establish billing agreement. Please try checking out again. If this problem persists please contact us."
				redirect_to tote_items_path
				return
			end
  	end

		if params[:testparam_fail_rtba_invalid]
			rtba.test_params = "failure"
		end					
  	
		#is ba legit?
		if !rtba.ba_valid?
			flash.now[:danger] = "The Billing Agreement we have on file is no longer valid. Please try to establish a new one by checking out again. If you continue to have problems please contact us."
			AdminNotificationMailer.general_message("Billing agreement invalid!", rtba.ba_id).deliver_now
			redirect_to tote_items_path
			return
		end

		#we have a legit billing agreement in place so now create a new authorization object and associate it with all appropriate other objects
		@rtauthorization = Rtauthorization.new(rtba: rtba)
		@current_tote_items = current_user_current_tote_items

		#TODO RtauthorizationsController 6: send authorization receipt email. when you send the email it should be sent by using current_user_current_unauthorized_tote_items. the email
		#should list subtotal and totals for all items that are now moving from ADDED to AUTHORIZED as well as a summary sentence for each new subscription being added

		@current_tote_items.each do |tote_item|

			#transition the tote_item to AUTHORIZED
			if tote_item.state?(:ADDED)
				tote_item.transition(:customer_authorized)
			end

			if !params[:testparam_fail_rtauthsave]
				#associate this tote_item with the new authorization
				@rtauthorization.tote_items << tote_item
			end

			#if this item came from a subscription, associate the subscription with this authorization
			if !tote_item.subscription.nil?
				@rtauthorization.subscriptions << tote_item.subscription
			end

		end

		if !@rtauthorization.save
			AdminNotificationMailer.general_message("Problem saving Rtauthorization!", @rtauthorization.errors.to_yaml).deliver_now
		end
  	
  	flash.now[:success] = "Payment authorized!"		

  end
end