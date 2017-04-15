class RtauthorizationsController < ApplicationController
  before_action :logged_in_user

  def index

    per_page = 10

    if current_user.account_type_is?(:ADMIN)
      #@authorizations = Authorization.all.paginate(:page => params[:page], :per_page => per_page)
      @rtauthorizations = Rtauthorization.all.paginate(:page => params[:page], :per_page => per_page)
    else
      #@authorizations = Authorization.joins(tote_items: :user).where(users: {id: current_user.id}).paginate(:page => params[:page], :per_page => per_page).distinct
      @rtauthorizations = Rtauthorization.joins(rtba: :user).where(users: {id: current_user.id}).paginate(:page => params[:page], :per_page => per_page).distinct
    end

    #this is some serious hack gnarly code. yes, i'm sticking two completely unrelated classes in the same array for use by
    #common code, treating them as though they have a common ancestor. nope. why? cause i'm in a hurry...
    #@all_auths = ((@authorizations.to_a + @rtauthorizations.to_a).sort_by &:created_at).reverse!

    #and here's a hack on the hack. this hack hack is being added as i go to put pagination on. i don't want to spend the time right now to figure out how to lace the Authorizations and
    #Rtauthorizations together. especially so because a business strategy for the indefinite future is to pretty much eliminate one time Authorization use. They actually still are in the
    #code but it's anedge case. first, the posting would have to be non-recurring. second, the user must be one who doesn't already have a billing agreement established with us. then
    #we still do expose to them the option of one time. actually, that's the only thing they could do since it's a one time purchase. then, after all this, they'd have to want to use this
    #auth view feature, which itself should be a rarely-used and non-critical feature. so don't pound it all out now. it's primarily a tool to use to track production progress (99.99% Rtauth)
    #or when problems arise with customer (99.99% Rtauth). in the 0.01% time we'll need to view an Auth we can just poke around the db manually. for now.
    @all_auths = @rtauthorizations

  end

  def show

    id = params[:id].to_i

    if id.nil?
      redirect_to rtauthorizations_path
      return
    end

    @subscriptions = []
    @tote_items = []

    if params[:rta]
      @auth = Rtauthorization.find_by(id: id)
    else
      @auth = Authorization.find_by(id: id)
    end

    if @auth.nil?
      redirect_to rtauthorizations_path
      return
    end

    #gotta make sure correct user here before proceeding    
    if !current_user.account_type_is?(:ADMIN) && (@auth.user != current_user)
      redirect_to rtauthorizations_path
      return
    end

    @subscriptions = @auth.checkout_subscriptions
    @tote_items = @auth.checkout_tote_items(@subscriptions)
    @items_total_gross = get_gross_tote(@tote_items)

  end

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