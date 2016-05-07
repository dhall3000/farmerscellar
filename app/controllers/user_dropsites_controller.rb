class UserDropsitesController < ApplicationController
  before_action :logged_in_user

  def create
    dropsite = Dropsite.find(params[:user_dropsite][:dropsite_id])
    current_user.set_dropsite(dropsite)    
  	flash[:success] = "Your delivery dropsite is now " + dropsite.name
  	redirect_to tote_items_path
  end

  private
    def user_dropsite_params
      params.require(:user_dropsite).permit(:user_id, :dropsite_id)
    end
end