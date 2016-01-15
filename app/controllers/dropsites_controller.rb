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
  end

  def show
  end

  def edit
  end

  def update
  end

  private
    def dropsite_params
      params.require(:dropsite).permit(:name, :phone, :hours, :address, :access_instructions)
    end
end
