class PickupsController < ApplicationController
	before_action :redirect_to_root_if_user_not_dropsite_user

  def new
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
  			@tote_items = @user.tote_items_to_pickup
  			@last_pickup = @user.pickups.last

  			#now create a new pickup to represent the current pickup  				 				
 				@user.pickups.create
        flash.now[:success] = "Thanks for checking out!"
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
