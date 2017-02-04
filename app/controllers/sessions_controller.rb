class SessionsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:spoof]

  def new

  end

  def spoof

    if spoofing?
      redirect_to root_url
      return
    end

    user = User.find_by(email: params[:email].downcase)
    if user.nil? || !user.valid?
      flash[:danger] = "Can't spoof #{params[:email]}. Email address not associated with a valid user account."
      redirect_to root_url
      return
    end

    session[:spoofing_admin_id] = current_user.id
    log_in user

    flash[:success] = "Now spoofing user #{user.email}"
    redirect_to user

  end

  def unspoof    

    if !spoofing?
      redirect_to root_url
      return
    end

    log_out
    log_in User.find(session[:spoofing_admin_id])
    session[:spoofing_admin_id] = nil
    flash[:success] = "All done spoofing"
    redirect_to users_path

  end

  def create

    #if we get to this action that means we were sent an email/pw combo
    #first let's see if we can get a user
    @user = User.find_by(email: params[:session][:email].downcase)

    if @user.nil?
      #ok we don't have a user account by this email. try to create one.
      @user = User.create(email: params[:session][:email].downcase, password: params[:session][:password])
      if @user.valid?
        @user.send_activation_email
        flash[:info] = "Account created. Please check your email to activate your account."
      end
    end

    if @user.valid?

      if create_session?(@user)

        if @user.account_type_is?(:DROPSITE)
          redirect_to new_pickup_path
        else
          redirect_back_or root_path
        end

        return              

      end    
      
    end

    flash.now[:danger] = "Invalid email/password combination. Please try again."
    render 'new'

  end

  def destroy
    log_out if logged_in?    
    redirect_to root_url
  end

  private

    def create_session?(user)

      if user.nil? || !user.valid?
        return false
      end

      if user.authenticate(params[:session][:password])        
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        return true        
      end

      return false
      
    end

end
