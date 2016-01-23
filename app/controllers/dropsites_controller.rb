class DropsitesController < ApplicationController
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
    
    @dropsites = Dropsite.all


#if this is an admin, fetch Dropsite.all
#however, if this is a customer, only show 'active' dropsites


  end

  def show
    @dropsite = Dropsite.find(params[:id])    
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
