class UsersController < ApplicationController

  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :show]
  before_action :correct_user,   only: [:show, :edit, :update]
  before_action :redirect_to_root_if_user_not_admin,     only: [:destroy, :index]
  before_action :redirect_to_root_if_user_lacks_access, only: [:destroy, :index, :show, :edit]
  before_action :correct_user_or_admin, only: [:show]

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  def index
    @users = User.paginate(page: params[:page])
    @producers = User.where(account_type: User.types[:PRODUCER]).order(:farm_name)
  end

  def new
  	@user = User.new
  end

  def show

    #we want farmer to be able to see all his past postings
    if @user.account_type > 0
      @postings = Posting.where(user_id: @user.id).order(delivery_date: :desc, id: :desc)
    end

    @recent_pickups = @user.pickups.order(created_at: :desc).limit(10)

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
  end

  def update    

    if params.has_key?(:user)
      if params[:user].has_key?(:access_code)
        #ok, user just provided the access code
        user_provided_access_code = params[:user][:access_code]
        db_access_code = AccessCode.find_by_id(user_provided_access_code)

        if db_access_code == nil
          flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
        else
          if db_access_code.user == nil
            db_access_code.user = current_user
            if db_access_code.save
              flash[:success] = "Access granted. Welcome to Farmer's Cellar!"
            else
              flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
            end
          else
            flash[:danger] = "That access code did not work. Please try again. If you continue to have difficulties, please contact us."
          end
        end        
        redirect_to root_url
      else        
        #user is just updating their profile
        if @user.update_attributes(user_params)
          flash_message = "Profile updated"          
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

      params.require(:user).permit(:name, :email, :password, :password_confirmation, :account_type, :address, :farm_name, :description_body, :agreement, :beta, :zip)

    end

    # Confirms the correct user.
    def correct_user

      @user = User.find_by(id: params[:id])
      if @user.nil?
        redirect_to root_path
        return
      end
      
      if !current_user?(@user)
        redirect_to(root_url)
      end
      
    end

    def correct_user_or_admin
      
      @user = User.find_by(id: params[:id])
      if @user.nil?
        redirect_to root_path
        return
      end

      if !current_user?(@user) && !current_user.account_type_is?(:ADMIN)
        redirect_to(root_url)
      end

    end

end
