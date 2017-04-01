class ProducersController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
    @producer = User.new    
    #@producer = User.new(name: "Palouse Poultry", email: "palouse@poultry.com", description: "good chicken", city: "Rosario", state: "WA", website: "http://www.palousepasturedpoultry.com", farm_name: "PP Poultry")
    get_producers_for_new
  end

  def create

    @producer = User.new(producer_params)
    @producer.password = "854f7f938d52415c8d20a7ca4afa3040"
    @producer.password_confirmation = "854f7f938d52415c8d20a7ca4afa3040"
    @producer.account_type = User.types[:PRODUCER]
    @producer.activated = true
    @producer.activated_at = Time.zone.now

    if @producer.save
      flash[:success] = "Producer created"
      redirect_to producer_path(@producer)
    else
      get_producers_for_new
      flash.now[:danger] = "Producer not created"
      render 'producers/new'
    end

  end

  def index
    @distributors = User.joins(:producers).order(:farm_name).distinct
    @producers = User.where(account_type: User.types[:PRODUCER]).where.not(id: @distributors.to_a).order(:farm_name)
  end

  def edit
    @producer = User.find(params[:id])
    get_producers_for_new
  end

  def update
    @producer = User.find(params[:id])
    if @producer.update_attributes(producer_params)
      flash[:success] = "Producer updated"
      redirect_to producer_path(@producer)
    else
      get_producers_for_new
      flash.now[:danger] = "Producer not updated"
      render 'edit'
    end
  end

  def show
    @producer = User.find(params[:id])
  end

  def destroy
  end

  private
    def producer_params
      params.require(:producer).permit(:name, :email, :description, :city, :state, :website, :farm_name, :distributor_id, :order_minimum_producer_net)
    end

    def get_producers_for_new
      @producers = User.where(account_type: User.types[:PRODUCER]).where.not(id: @producer).order(:farm_name)
    end
end