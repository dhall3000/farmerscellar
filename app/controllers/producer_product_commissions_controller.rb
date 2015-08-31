class ProducerProductCommissionsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def index
  end

  def show
  end

  def new
    @ppc = ProducerProductCommission.new
    @products = Product.all
    @producers = User.where(account_type: User.types[:PRODUCER])
  end

  def create
    @ppc = ProducerProductCommission.new(producer_product_commission_params)

    if @ppc.save
      flash[:success] = "Commission creation succeeded."
      render 'index'
    else
      @products = Product.all
      @producers = User.where(account_type: User.types[:PRODUCER])
      render 'new'
    end

  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
    def producer_product_commission_params
      params.require(:producer_product_commission).permit(:user_id, :product_id, :commission)
    end  
end