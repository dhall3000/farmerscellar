class ProducerProductUnitCommissionsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def index
  end

  def show
    @ppc = ProducerProductUnitCommission.where(product_id: params[:product_id], user_id: params[:user_id]).order(:created_at).last
  end

  def new
    @ppc = ProducerProductUnitCommission.new
    load_data
  end

  def retail_helper

        
    @ppc = ProducerProductUnitCommission.new
    load_data

    commission = params[:commission].to_f
    producer_net = params[:producer_net].to_f
    @retail_price = get_retail_price(commission, producer_net)

    render new_producer_product_unit_commission_path

  end

  def create

    user_id = params[:producer_product_unit_commission][:user_id]
    product_id = params[:producer_product_unit_commission][:product_id]
    unit_id = params[:producer_product_unit_commission][:unit_id]

    if params[:producer_product_unit_commission][:commission].nil?
      retail = params[:retail].to_f
      producer_net = params[:producer_net].to_f
      commission_factor = make_commission_factor(retail, producer_net)      
      @ppc = ProducerProductUnitCommission.new(user_id: user_id, product_id: product_id, unit_id: unit_id, commission: commission_factor)
      @ppc.retail = retail
      @ppc.producer_net = producer_net
    else
      @ppc = ProducerProductUnitCommission.new(producer_product_unit_commission_params)
    end    

    if @ppc.save
      flash.now[:success] = "Commission creation succeeded #{@ppc.commission.to_s}"
      @ppc = @ppc.dup
    else
      flash.now[:danger] = "Commission creation failed"
    end

    load_data
    render 'new'

  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
    def producer_product_unit_commission_params
      params.require(:producer_product_unit_commission).permit(:user_id, :product_id, :unit_id, :commission)
    end

    def load_data   
      @producers = User.where(account_type: User.types[:PRODUCER])
      @products = Product.all
      @units = Unit.all
    end

end