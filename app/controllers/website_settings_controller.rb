class WebsiteSettingsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:edit, :update]

  def edit
  	@website_setting = WebsiteSetting.find(params[:id])	
  end

  def update
  	@website_setting = WebsiteSetting.find(params[:id])
  	@website_setting.update(website_setting_params)

  	if @website_setting.save
  	  flash[:success] = "website settings updated successfully"
  	  render 'website_settings/edit'
  	else
  	  flash[:danger] = "website settings failed to update"
  	  redirect_to edit_website_setting_path(params[:id])
  	end  	

  end

  private

    def website_setting_params
      params.require(:website_setting).permit(:new_customer_access_code_required)
    end
end
