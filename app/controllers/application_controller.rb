class ApplicationController < ActionController::Base  
  include SessionsHelper, ToteItemsHelper

  before_action :redirect_dropsite_user, :fetch_header_data
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    log_out
    flash[:danger] = "Oops, you got logged out. If this keeps happening please contact us. Thank you!"
    redirect_to login_path    
  end

  private

    #we want to block dropsite users for all app functionality except PickupsController
    def redirect_dropsite_user      
      if logged_in? && current_user.account_type_is?(:DROPSITE)
        if self.class.to_s != "PickupsController"
          redirect_to(new_pickup_url)
        end
      end
    end

    def fetch_header_data
      
      if !logged_in?
        return
      end      

      if current_user.header_data_dirty || !header_data_valid?
        refresh_header_data        
      end

    end

end