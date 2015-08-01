class AccessCodesController < ApplicationController
  before_action :admin_user, only: [:new, :create]

  def new
  	@access_code = AccessCode.new
  end

  def create
    @access_code = AccessCode.new(access_code_params)
    @access_code.save
  end

  def update
  end

  private
  
    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.account_type > 1
    end

    def access_code_params
      params.require(:access_code).permit(:notes)
    end

end
