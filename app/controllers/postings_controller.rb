class PostingsController < ApplicationController
  def new
  	#@posting = Posting.new(user_id: current_user.id)  	
  	@posting = current_user.postings.new
  	@products = Product.all
  	@unit_categories = UnitCategory.all
  	@unit_kinds = UnitKind.all
  end

  def create  	
  	@posting = Posting.new(posting_params)
  	if @posting.save
  	  flash[:info] = "Your new posting is now live!"
      redirect_to root_url
    else
      render 'new'
  	end

  end

  private

    def posting_params
      
      posting = params.require(:posting).permit(:description, :quantity_available, :price, :user_id, :product_id, :unit_category_id, :unit_kind_id)
      posting[:user_id] = current_user[:id]

      unit_kind = UnitKind.all.find_by(id: posting[:unit_kind_id])
      posting[:unit_category_id] = unit_kind.unit_category.id

      posting

    end

end