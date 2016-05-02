class RtauthorizationsController < ApplicationController
  def new

  	#note: this is a bit of a misnomer. this #new action might make you think we're creating a new Rtauthorization. We're not. It's a hack
  	#for the uncommon event of creating a new Rtba object. I didn't want to create a separate controller just for one rtba action
  	#and that one (rare) action is related to and in the flow of rtauths so I just decided to throw this hack in here for now

  	if USEGATEWAY
  		details = GATEWAY.details_for(params[:token])
  	else
  		if params[:success]
  			details = RtauthorizationsHelper::FakeDetailsFor.new("success")
  		else
  			details = RtauthorizationsHelper::FakeDetailsFor.new("failure")
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
			ba = GATEWAY.store(token, {})
			if ba.success?				
				rtba = Rtba.new(token: token, ba_id: ba.authorization, user: current_user, active: true)
				if !rtba.valid?
					AdminNotificationMailer.general_message("Problem creating rtba!", rtba.errors.to_yaml).deliver_now
					#TODO RtauthorizationsController 2: problem saving Rtba
					#flash problem
					#redirect
				end				
				rtba.save	
			else
				AdminNotificationMailer.general_message("Problem creating paypal billing agreement!", ba.to_yaml).deliver_now
				#TODO RtauthorizationsController 3: Problem creating paypal billing agreement
				#flash problem
				#redirect
			end
  	end

  	if rtba.nil?
  		#TODO RtauthorizationsController 4: rtba is nil
  		#communicate problems to user
  		#redirect
  	end
  	
		#is ba legit?
		if !rtba.ba_valid?
			#TODO RtauthorizationsController 5: billing agreement on file is not valid
			#flash danger "The Billing Agreement we have on file is no longer valid. Please try to establish a new one by checking out again below. If you continue to have problems please contact us"
			#email admin
			#redirect to tote			
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

			#associate this tote_item with the new authorization
			@rtauthorization.tote_items << tote_item

			#if this item came from a subscription, associate the subscription with this authorization
			if !tote_item.subscription.nil?
				@rtauthorization.subscriptions << tote_item.subscription
			end

		end

		if !@rtauthorization.save
			problem_string = "problem: a new @rtauthorization did not save. Probably better investigate why before Commitment Zone Starts hit."
			puts problem_string
			AdminNotificationMailer.general_message("Problem saving Rtauthorization!", problem_string).deliver_now
		end
  	
  	flash.now[:success] = "Payment authorized!"		

  end
end