class ProducerProductCommissionsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def index
  end

  def show
    @ppc = ProducerProductCommission.where(product_id: params[:product_id], user_id: params[:user_id]).order(:created_at).last
  end

  def new
    @ppc = ProducerProductCommission.new
    @products = Product.all
    @producers = User.where(account_type: User.types[:PRODUCER])
  end

  def create

    user_id = params[:producer_product_commission][:user_id]
    product_id = params[:producer_product_commission][:product_id]

    if params[:producer_product_commission][:commission].nil?
      retail = params[:retail].to_f
      producer_net = params[:producer_net].to_f
      commission_factor = make_commission_factor(retail, producer_net)      
      @ppc = ProducerProductCommission.new(user_id: user_id, product_id: product_id, commission: commission_factor)
    else
      @ppc = ProducerProductCommission.new(producer_product_commission_params)
    end    

    if @ppc.save
      flash[:success] = "Commission creation succeeded."
      redirect_to producer_product_commission_path(id: 1, product_id: product_id, user_id: user_id)
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