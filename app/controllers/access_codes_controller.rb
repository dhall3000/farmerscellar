class AccessCodesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:new, :create]

  def new
  	@access_code = AccessCode.new    
  end

  def create
    @access_code = AccessCode.new(access_code_params)    
    @access_code.save
    @code = @access_code.id
  end

  private
  
    def access_code_params      
      params.require(:access_code).permit(:notes)
    end

end
