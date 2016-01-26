class UserDropsitesController < ApplicationController
  before_action :redirect_to_root_if_not_logged_in

  def create
    dropsite = Dropsite.find(params[:user_dropsite][:dropsite_id])
    current_user.dropsites << dropsite
    current_user.save
  	flash[:success] = "Your delivery dropsite is now " + dropsite.name
  	redirect_to tote_items_path
  end

  private
    def user_dropsite_params
      params.require(:user_dropsite).permit(:user_id, :dropsite_id)
    end
end