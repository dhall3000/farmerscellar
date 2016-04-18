class PickupsController < ApplicationController
	before_action :redirect_to_root_if_user_not_dropsite_user

  def new
  	#first step is to blast the session in case we're getting here due to someone clicking "all done"
  	@pickup_code = PickupCode.new
  end

  def create

  	entered_code = params[:pickup_code]
  	@pickup_code = PickupCode.new(code: entered_code, user: current_user)

  	if @pickup_code.valid?
  		@pickup_code = PickupCode.find_by(code: entered_code)  		
  		if @pickup_code.nil?
	  		flash.now[:danger] = "Invalid code entry"
	  		render 'pickups/new'	  	
  		else
  			@user = @pickup_code.user
  			#get a product list of everything that's been delivered since the last pickup (or 7 days, whichever is more recent)
  			#TODO: for now for 'delivered' we're going to use toteitem states FILLED or PURCHASED
  			#this will eventually change though once we overhaul the toteitem statemachine
  			
  			#A) 7 days ago
  			last_pickup = 7.days.ago
  			if @user.pickups.any?
  				#or...
  				#B) the last pickup
  				last_pickup = @user.pickups.last.created_at
  			end

  			#whichever is more recent
  			cutoff = [last_pickup, 7.days.ago].max
  			#@tote_items = @user.tote_items.where(status: [ToteItem.states[:FILLED], ToteItem.states[:PURCHASED]], "updated_at > ?", last_pickup)
  			#TODO: the below line isn't quite right. it will display toteitems that have been purchased in the last 7 days even though it could be that
  			#some purchased items were actually delivered a longer time period ago like, say, 9 days ago. the reason is because the .updated_at field
  			#will get modified when the purchas goes through. leaving it this way cause i'll be redoing it anyway after cleaning up the toteitem state machine
  			@tote_items = @user.tote_items.where(status: [ToteItem.states[:FILLED], ToteItem.states[:PURCHASED]]).where("updated_at > ?", last_pickup)
  			#now create a new pickup to represent the current pickup  				 				
 				@user.pickups.create
  		end
  	else
  		flash.now[:danger] = "Invalid code entry"
  		render 'pickups/new'
  	end

  end

  private
	  def redirect_to_root_if_user_not_dropsite_user
	    if !logged_in? || !current_user.account_type_is?(:DROPSITE)
	      redirect_to(root_url)
	    end
	  end
end
