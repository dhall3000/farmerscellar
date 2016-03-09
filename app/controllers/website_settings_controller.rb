class WebsiteSettingsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def edit
  	@website_setting = WebsiteSetting.find(params[:id])	
  end

  def update

  	@website_setting = WebsiteSetting.find(params[:id])
  	
  	if @website_setting.update_attributes(website_setting_params)
  	  flash.now[:success] = "website settings updated successfully"
  	  render 'website_settings/edit'
  	else
  	  flash[:danger] = "website settings failed to update"
  	  redirect_to edit_website_setting_path(params[:id])
  	end  	

  end

  private

    def website_setting_params
      params.require(:website_setting).permit(:new_customer_access_code_required, :recurring_postings_enabled)
    end
end
