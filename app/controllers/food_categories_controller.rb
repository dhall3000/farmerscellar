class FoodCategoriesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def recategorize_products

    products = Product.where(id: params[:products])
    to_category = FoodCategory.find(params[:to_category])

    products.update_all(food_category_id: to_category.id)

    redirect_to food_categories_path    

  end

  def index    
    @root = FoodCategory.where(parent: nil).first
    @homeless_products = Product.where(food_category: nil).order(:name)
  end

  def show
    @food_category = FoodCategory.find(params[:id])    
  end

  def new
    @food_category = FoodCategory.new
    @food_categories = FoodCategoriesController.helpers.get_options_for_select
  end

  def create

    name = params[:food_category][:name]
    parent_id = params[:parent]

    if parent_id && !parent_id.blank?
      parent_food_category = FoodCategory.find(parent_id)
    end
    
    food_category = FoodCategory.new(name: name, parent: parent_food_category)

    if food_category.save
      flash[:success] = "FoodCategory created"
    else
      flash[:danger] = "FoodCategory not created"
    end

    redirect_to food_categories_path

  end

  def edit
    @food_category = FoodCategory.find(params[:id])
    @food_categories = FoodCategoriesController.helpers.get_options_for_select
    @upload = Upload.new
  end

  def update    

    @food_category = FoodCategory.find(params[:id])
    old_name = @food_category.name
    @food_category.name = params[:food_category][:name]
    @parent_food_category = FoodCategory.find_by(id: params[:parent])
    @food_category.parent = @parent_food_category

    if @food_category.save
      flash[:success] = "#{old_name} FoodCategory updated"
    else
      flash[:danger] = "#{old_name} FoodCategory not updated"
    end

    redirect_to food_category_path(@food_category)

  end

  def destroy
  end

  private
    def create_params
      return params.require(:food_category).permit(:name, :parent)
    end

end