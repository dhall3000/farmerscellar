class UnitsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  before_action :get_unit, only: [:show, :edit, :update, :destroy]
  before_action :get_new_name, only: [:create, :update]

  def new
    @unit = Unit.new
  end

  def create
    existing_unit = Unit.find_by(name: @new_name)
    @unit = Unit.new(name: @new_name)

    if existing_unit
      flash.now[:danger] = "Unit with that name already exists"
      render 'units/new'
      return
    end

    if @unit.save
      flash[:success] = "Unit created"
      redirect_to @unit
      return
    else
      flash.now[:danger] = "Unit not created"
      render 'units/new'
      return
    end

  end

  def destroy
    
    if @unit.nil?
      flash[:danger] = "Couldn't find that unit to destroy"
      redirect_to units_path
      return
    end

    if @unit.destroy
      flash[:success] = "Unit destroyed"
      redirect_to units_path
      return
    else
      flash[:danger] = "Unit not destroyed"
      redirect_to @unit
      return
    end

  end

  def index
    @units = Unit.all.order(:name)
  end

  def show
  end

  def edit
  end

  def update

    existing_unit = Unit.find_by(name: @new_name)

    if existing_unit
      flash.now[:danger] = "Unit with that name already exists"
      render 'units/edit'
      return
    end

    if @unit
      @unit.update(name: @new_name)
      flash[:success] = "Unit name updated"
    else
      flash[:danger] = "Unit name not updated"
    end

    redirect_to @unit

  end

  private

    def get_unit
      @unit = Unit.find_by(id: params[:id])
    end

    def get_new_name
      @new_name = params[:unit][:name]
    end

end