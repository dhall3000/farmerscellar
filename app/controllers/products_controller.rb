class ProductsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
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
  end

  def update
  end

  def show
  end

  def index
    @products = Product.all.order(:name)
  end

  def destroy
  end

  private
    def product_params
      params.require(:product).permit(:name)
    end
end