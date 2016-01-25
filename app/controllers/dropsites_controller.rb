class DropsitesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:new, :create, :destroy, :edit, :update]

  def new
    @dropsite = Dropsite.new    
  end

  def create
    @dropsite = Dropsite.new(dropsite_params)
    if @dropsite.save
      flash[:success] = "Dropsite created!"
      redirect_to root_url
    else
      render 'new'      
    end
  end

  def destroy
  end

  def index

    if current_user != nil && current_user.account_type == User.types[:ADMIN]
      @dropsites = Dropsite.all    
    else
      @dropsites = Dropsite.where(active: true)
    end    

  end

  def show
    @dropsite = Dropsite.find(params[:id])    
    @user_dropsite = UserDropsite.new(user_id: current_user.id, dropsite_id: @dropsite.id)
  end

  def edit
    @dropsite = Dropsite.find(params[:id])    
  end

  def update        
    @dropsite = Dropsite.find(params[:id])
    if @dropsite.update_attributes(dropsite_params)      
      flash[:success] = "Dropsite updated"
      redirect_to @dropsite
    else
      render 'edit'
    end
  end

  private
    def dropsite_params
      params.require(:dropsite).permit(:name, :phone, :hours, :address, :access_instructions, :active, :city, :state, :zip)
    end
end
