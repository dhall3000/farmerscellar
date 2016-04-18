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
