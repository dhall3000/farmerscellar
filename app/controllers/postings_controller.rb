class PostingsController < ApplicationController
  before_action :logged_in_user

  def new  	

    if params[:posting_id].nil?
      @posting = current_user.postings.new
    else
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup
    end

    load_posting_choices

  end

  def index
    # we only want to pull postings whose delivery date is >= today and that are 'live'
    @postings = Posting.where("delivery_date >= ? and live = ?", Date.today, true).order(delivery_date: :desc, id: :desc)
  end

  def create        
  	@posting = Posting.new(posting_params)

  	if @posting.save
  	  flash[:info] = "Your new posting is now live!"
      redirect_to postings_path
    else      
      load_posting_choices
      render 'new'
  	end

  end

  def edit
    #if an admin is doing this we want him to be able to edit it but if it's a farmer we want to put
    #contraints on. however, for now all we're implementing is the ability for farmer to switch between making the 
    #posting live or not live
    @posting = Posting.find(params[:id])        
  end

  def update    
    @posting = Posting.find(params[:id])

    if @posting.update_attributes(posting_params)      
      flash[:success] = "Posting updated!"
      redirect_to current_user
    else
      render 'edit'
    end

  end

  def show
    @posting = Posting.find(params[:id])
  end

  private

    def load_posting_choices
      @products = Product.all
      @unit_categories = UnitCategory.all
      @unit_kinds = UnitKind.all
      @delivery_dates = next_delivery_dates(4)
    end

    def posting_params

      posting = params.require(:posting).permit(:description, :quantity_available, :price, :user_id, :product_id, :unit_category_id, :unit_kind_id, :delivery_date, :live)
      posting[:user_id] = current_user[:id]

      unit_kind = UnitKind.all.find_by(id: posting[:unit_kind_id])

      if !unit_kind.nil?
        posting[:unit_category_id] = unit_kind.unit_category.id
      end

      #this hocus pocus has to do with some strange gotchas. a check box sends in a "1" or "0", both of which evaluate to true for a boolean type,
      #which the live attribute is. so i'm just hackishly converting from one to the other to be ridiculously specific
      if posting.has_key?(:live)
        if posting[:live] == "0"
          posting[:live] = false
        else
          if posting[:live] == "1"
            posting[:live] = true
          end
        end
      end

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