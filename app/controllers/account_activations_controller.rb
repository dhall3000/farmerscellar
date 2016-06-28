class AccountActivationsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create]

  def new

    if current_user && current_user.activated?
      redirect_to root_url
      return
    end
    
  end

  def create

    if current_user

      if current_user.activated?
        flash[:info] = "Account already activated."
      else
        current_user.send_activation_email
        flash[:info] = "Please check your email to activate your account."        
      end
            
    end

    redirect_to tote_items_path
    
  end

  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to postings_path
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
end