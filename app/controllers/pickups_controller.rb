class PickupsController < ApplicationController
	before_action :redirect_to_root_if_user_not_dropsite_user

  def new
  	#first step is to blast the session in case we're getting here due to someone clicking "all done"
  end

  def create

  end

  private
	  def redirect_to_root_if_user_not_dropsite_user
	    if !logged_in? || !current_user.account_type_is?(:DROPSITE)
	      redirect_to(root_url)
	    end
	  end
end
