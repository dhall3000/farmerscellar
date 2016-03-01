class PostingsController < ApplicationController
  before_action :logged_in_user
  before_action :redirect_to_root_if_not_producer, only: [:new, :create, :edit, :update]
  before_action :redirect_to_root_if_user_not_admin, only: [:no_more_product]

  def new  	

    if params[:posting_id].nil?
      @posting = current_user.postings.new
      
      #if you are doing dev work on the create method and want the new form autopopulated for sanity's sake, uncomment this line
      #@posting = Posting.new(live: true, delivery_date: Time.zone.now + 4.days, product_id: 8, quantity_available: 100, price: 2.50, user_id: User.find_by(name: "f4"), unit_category_id: UnitCategory.find_by(name: "Weight"), unit_kind_id: UnitKind.find_by(name: "Pound"), description: "best celery ever!")
    else
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup
    end

    load_posting_choices

  end

  def index

    if current_user.account_type == User.types[:CUSTOMER] || current_user.account_type == User.types[:PRODUCER]
      #for customers, we only want to pull postings whose delivery date is >= today and that are 'live'
      @postings = Posting.where("delivery_date >= ? and live = ?", Time.zone.today, true).order(delivery_date: :desc, id: :desc)
    elsif current_user.account_type == User.types[:ADMIN]
      #for admins, same thing but we want to see the unlive as well
      @postings = Posting.where("delivery_date >= ?", Time.zone.today).order(delivery_date: :desc, id: :desc)
    end

  end

  def create

  	@posting = Posting.new(posting_params)

  	if @posting.save
      if @posting.live
        flash[:info] = "Your new posting is now live!"
      else
        flash[:info] = "Your posting was created but is not live as you specified during creation."
      end  	  
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

  def no_more_product

    #this action gets called by an admin when he runs out of product before he runs out of orders. in this case what needs
    #to happen is all the outstanding COMMITTED and FILLPENDING orders need to get transitioned to NOTFILLED
    @tote_items_not_filled = ToteItem.where(posting_id: params[:posting_id]).where("status = ? OR status = ?", ToteItem.states[:COMMITTED], ToteItem.states[:FILLPENDING])    
    @tote_items_not_filled.update_all(status: ToteItem.states[:NOTFILLED])
    
    @tote_items_filled = ToteItem.select(:id).where(posting_id: params[:posting_id], status: ToteItem.states[:FILLED])
    @tote_items_not_filled = ToteItem.select(:id).where(posting_id: params[:posting_id], status: ToteItem.states[:NOTFILLED])

  end

  private

    def load_posting_choices
      @products = Product.all.order(:name)
      @unit_categories = UnitCategory.all
      @unit_kinds = UnitKind.all
      @delivery_dates = next_delivery_dates
      @producers = User.where(account_type: User.types[:PRODUCER])
    end

    def posting_params

      posting = params.require(:posting).permit(
        :description,
        :quantity_available,
        :price,
        :user_id,
        :product_id,
        :unit_category_id,
        :unit_kind_id,
        :live,
        :delivery_date,
        :commitment_zone_start
        )

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

    def next_delivery_dates

      i = 3      
      dates = []

      while i < 30
        d = Time.zone.today + i
        if !d.sunday?
          dates << d
        end

        i +=1
      end      

      dates

    end

end