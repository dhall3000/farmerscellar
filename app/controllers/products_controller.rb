class ProductsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
    @food_categories = FoodCategoriesController.helpers.get_options_for_select
    @product = Product.new    
  end

  def create

    @product = Product.new(product_params)

    if @product.save
      flash[:success] = "Product saved"
      redirect_to products_path
    else
      render 'new'
    end
    
  end

  def edit    
    @food_categories = FoodCategoriesController.helpers.get_options_for_select
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])

    if @product.update_attributes(product_params)
      flash[:success] = "Product updated"
      redirect_to product_path(@product)
      return
    else
      flash[:danger] = "Product not updated"
      redirect_to edit_product_path(@product)
      return
    end
  end

  def show    
    @product = Product.find(params[:id])
  end

  def index
    @products = Product.all.order(:name)
  end

  def destroy
  end

  private
    def product_params
      params.require(:product).permit(:name, :food_category_id)
    end
end