class PostingsController < ApplicationController
  def new  	

    if params[:posting_id].nil?
      @posting = current_user.postings.new
    else
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup
    end

  	@products = Product.all
  	@unit_categories = UnitCategory.all
  	@unit_kinds = UnitKind.all
    @delivery_dates = next_delivery_dates(4)
  end

  def index
    # we only want to pull postings whose delivery date is >= today
    @postings = Posting.where("delivery_date >= ?", Date.today)
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

  def show
    @posting = Posting.find(params[:id])
  end

  private

    def posting_params
      
      posting = params.require(:posting).permit(:description, :quantity_available, :price, :user_id, :product_id, :unit_category_id, :unit_kind_id, :delivery_date)
      posting[:user_id] = current_user[:id]

      unit_kind = UnitKind.all.find_by(id: posting[:unit_kind_id])
      posting[:unit_category_id] = unit_kind.unit_category.id

      posting

    end

    def next_friday
      i = 1
      while !(Date.today + i).friday?   
        i += 1
      end
      Date.today + i
    end

    def next_delivery_dates(num_dates)

      dates = []

      if num_dates > 0
        dates << next_friday
      end

      if num_dates > 1
        i = 1
        while i < num_dates
          dates << dates.last + 7  
          i += 1
        end    
      end  

      dates

    end

end