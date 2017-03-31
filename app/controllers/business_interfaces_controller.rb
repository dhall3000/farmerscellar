class BusinessInterfacesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
    @business_interface = BusinessInterface.new    
    get_producers_for_new    
  end

  def create

    @business_interface = BusinessInterface.new(business_interface_params)
    if @business_interface.save
      flash[:success] = "BusinessInterface created"
      redirect_to business_interface_path @business_interface
      return
    else
      get_producers_for_new
      flash.now[:danger] = "BusinessInterface not created"
      render 'business_interfaces/new'
      return
    end

  end

  def edit
    @business_interface = BusinessInterface.find(params[:id])
    get_producers_for_new
  end

  def update

    @business_interface = BusinessInterface.find(params[:id])

    if @business_interface.update_attributes(business_interface_params)      
      flash[:success] = "BusinessInterface updated"
      redirect_to @business_interface
    else
      get_producers_for_new
      render 'edit'
      return
    end
    
  end

  def show
    @business_interface = BusinessInterface.find(params[:id])
  end

  def index
    @business_interfaces = BusinessInterface.all.order(:name)
  end

  private
    def business_interface_params
      params.require(:business_interface).permit(
        :name, :order_email, :order_instructions, :paypal_email, :user_id, :payment_method, :payment_time, :payment_receipt_email
        )
    end

    def get_producers_for_new            
      @producers = User.includes(:business_interface).where(account_type: User.types[:PRODUCER], business_interfaces: {id: [nil, @business_interface]})
    end
end