module SessionsHelper

  def log_in(user)
    session[:user_id] = user.id
    UserAccountState.ensure_state_exists(user)
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # Returns true if the given user is the current user.
  def current_user?(user)
    user == current_user
  end

  def redirect_to_root_if_not_producer
    if !logged_in? || current_user.account_type < 1
      redirect_to(root_url)
    end
  end

  def redirect_to_root_if_user_not_admin
    if !logged_in? || current_user.account_type < 2    
      redirect_to(root_url)
    end
  end

  def redirect_to_root_if_user_lacks_access
    if !user_has_access?
      redirect_to(root_url)
    end
  end

  def user_has_access?

    #if the user's not even logged in, no access
    if !logged_in?
      return false
    end

    #does the current user have an access code plugged in? if so, they always have access
    if !current_user.access_code.nil?
      return true
    end

    #we always require an access code for farmers because we don't want any tom, dick or harry
    #posting garbage ads to our site. so what we're doing here is granting access to anybody who doesn't
    #have an access code if we're in a not-requiring-access-code state UNLESS you are a farmer
    if !WebsiteSetting.order("website_settings.id").last.new_customer_access_code_required
      if current_user.account_type == 0 || current_user.account_type == 2 || current_user.account_type == 3
        return true
      end
    end

    return false    

  end

  #NOTE!: this is half implemented and zero tested. it's a good concept but found another way around my intent here.
  #it's not getting used anywhere yet
  def redirect_to_if_not_logged_in(redirect_path, flash_message)
    if !logged_in?    
      store_location
      flash[:danger] = "Please log in."
      redirect_to login_url
    end
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget(user)
    if user != nil
      user.forget
    end
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Redirects to stored location (or to the default).
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.url if request.get?
  end

  # Confirms a logged-in user.
  def logged_in_user
    if !logged_in?
      store_location
      flash[:danger] = "Please log in or sign up."
      redirect_to login_url
    end
  end

end
