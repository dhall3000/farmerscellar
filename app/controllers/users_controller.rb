class UsersController < ApplicationController

  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def new
  	@user = User.new
  end

  def show
  	@user = User.find(params[:id])
  end

  def create    
    @user = User.new(user_params)    
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
    	render 'new'
    end
    		
  end

  def edit
    @user = User.find(params[:id])
  end

  def update    
    @user = User.find(params[:id])
    agreement = @user.agreement            

    if params.has_key?(:user)
      if params[:user].has_key?(:access_code)
        #ok, user just provided the access code
        user_provided_access_code = params[:user][:access_code]
        db_access_code = AccessCode.find_by_id(user_provided_access_code)

        if db_access_code == nil
          #TODO: need to tell user the code didn't work. (it didn't work because the access code doesn't exist. try again or contact us.
            flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
        else
          if db_access_code.user == nil
            #TODO: this is the success case. set the accesscode.userid == currentuser.id and flash success
            db_access_code.user = current_user
            if db_access_code.save
              flash[:success] = "Access granted. Welcome to Farmer's Cellar!"
            else
              flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
            end
          else
            #TODO: there was a problem. this accesscode.userid was already assigned. it probably belongs to someone else but we haven't checked for that yet. flash error and move on.
            flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
          end
        end        
        redirect_to root_url
      else        
        #user is just updating their profile
        if @user.update_attributes(user_params)
          flash_message = "Profile updated"      
          if agreement != true and @user.agreement == true
            #flash_message = "Request for approval received. A staff member will be in touch with you shortly!"
          end
          flash[:success] = flash_message
          redirect_to @user
        else
          render 'edit'
        end
      end
    end
  end

  private

    def user_params

      #david added this hack to attempt to keep folks from giving themselves admin privs. not even sure if it works!
      if params[:user][:account_type].to_i > 1 
        params[:user][:account_type] = 0.to_s
      end

      params.require(:user).permit(:name, :email, :password, :password_confirmation, :account_type, :address, :farm_name, :description, :agreement)

    end

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end

    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.account_type > 1
    end

end
