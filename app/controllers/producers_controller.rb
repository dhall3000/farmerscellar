class ProducersController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
    @producer = User.new    
    #@producer = User.new(name: "Palouse Poultry", email: "palouse@poultry.com", description: "good chicken", city: "Rosario", state: "WA", website: "http://www.palousepasturedpoultry.com", farm_name: "PP Poultry")
    @producers = User.where(account_type: User.types[:PRODUCER])    
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
      @producers = User.where(account_type: User.types[:PRODUCER])
      flash.now[:danger] = "Producer not created"
      render 'producers/new'
    end

  end

  def index
    @distributors = User.joins(:producers).order(:farm_name).distinct
    @producers = User.where(account_type: User.types[:PRODUCER]).where.not(id: @distributors.to_a).order(:farm_name)
  end

  def edit
  end

  def update
  end

  def show
  end

  def destroy
  end

  private
    def producer_params
      params.require(:producer).permit(:name, :email, :description, :city, :state, :website, :farm_name, :distributor_id, :order_minimum_producer_net)
    end
end