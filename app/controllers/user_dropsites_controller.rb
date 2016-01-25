class UserDropsitesController < ApplicationController
  def create
    dropsite = Dropsite.find(params[:user_dropsite][:dropsite_id])
    current_user.dropsites << dropsite
    current_user.save
  	#user_dropsite = UserDropsite.new(user_dropsite_params)

  	#user_dropsite.save
  	flash[:success] = "Your delivery dropsite is now " + dropsite.name
  	redirect_to root_url
  end

  private
    def user_dropsite_params
      params.require(:user_dropsite).permit(:user_id, :dropsite_id)
    end
end