class PostingsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update]
  before_action :redirect_to_root_if_not_producer, only: [:new, :create, :edit, :update]
  
  def new  	

    posting_to_clone = nil

    if params[:posting_id]
      #we're copying a posting
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup

      if spoofing?
        @producer_net = posting_to_clone.get_producer_net_unit
      end
    else
      @posting = current_user.postings.new(live: true, delivery_date: Time.zone.now.midnight + 2.days, order_cutoff: Time.zone.now.midnight + 1.day)
      #if you are doing dev work on the create method and want the new form autopopulated for sanity's sake, uncomment this line
      #@posting = Posting.new(live: true, delivery_date: Time.zone.now + 4.days, product_id: 8, price: 2.50, user_id: User.find_by(name: "f4"), unit_category_id: UnitCategory.find_by(name: "Weight"), unit_kind_id: UnitKind.find_by(name: "Pound"), description_body: "best celery ever!")
    end

    @posting.build_posting_recurrence
    load_posting_choices

    if posting_to_clone && posting_to_clone.posting_recurrence
      @posting.posting_recurrence.frequency = posting_to_clone.posting_recurrence.frequency
    end

  end

  def index

    @food_category = FoodCategory.where(name: params[:food_category]).first
    if @food_category.nil?
      @food_category = FoodCategory.where(parent: nil).first
    end

    #this is the upcoming sunday at midnight
    next_week_start = start_of_next_week    
    next_week_end = next_week_start + 7.days
    limit = 10

    products_under = Product.none
    products_at = Product.none

    if @food_category

      products_under = @food_category.products_under
      products_at = @food_category.products
      if products_under        
        products = products_at.or(products_under)        
      else
        products = products_at
      end

      @this_weeks_postings = get_postings(products_at, Time.zone.now.midnight, next_week_start)
      if !@this_weeks_postings.any?
        @this_weeks_postings = get_postings(products_under, Time.zone.now.midnight, next_week_start, limit)
      end

      @next_weeks_postings = get_postings(products_at, next_week_start, next_week_end)
      if !@next_weeks_postings.any?
        @next_weeks_postings = get_postings(products_under, next_week_start, next_week_end, limit)
      end

      @future_postings = get_postings(products_at, next_week_end, next_week_end + 10.years)
      if !@future_postings.any?
        @future_postings = get_postings(products_under, next_week_end, next_week_end + 10.years, limit)
      end

    else      
      @this_weeks_postings = get_postings(Product.all, Time.zone.now.midnight, next_week_start, limit)
      @next_weeks_postings = get_postings(Product.all, next_week_start, next_week_end, limit)
      @future_postings = get_postings(Product.all, next_week_end, next_week_end + 10.years, limit)
    end

  end

  def get_postings(products, start_time, end_time, limit = nil)    

    return_postings = Posting.joins(:product).where(product: products).where("delivery_date >= ? and delivery_date < ? and live = ? and state = ?", start_time, end_time, true, Posting.states[:OPEN]).order(:price)

    if limit
      return_postings = return_postings.limit(limit)
    end    
    
    return return_postings

  end

  def create

  	@posting = Posting.new(posting_params)

    #this was added so that if we're copying a non-live posting the user doesn't have to take the extra step of edit/update'ing to turn this copy 'on'
    @posting.live = true

    #if posting_recurrence_params are repeating, associate a new recurrence with this posting
    if !posting_recurrence_params.nil? && posting_recurrence_params[:on] && posting_recurrence_params[:frequency].to_i > PostingRecurrence.frequency[0][1]      
      posting_recurrence = PostingRecurrence.new(posting_recurrence_params)
      posting_recurrence.postings << @posting            
    end

    #if this is an admin making a new posting he has a feature where he can short-circuit manually creating the commission by just specifying the 
    #producer_net right on the posting creation form. here we're checking for that and creating a new commission on the fly
    if spoofing? && !params[:producer_net].blank?
      producer_net = params[:producer_net].to_f
      if producer_net > 0
        commission_factor = make_commission_factor(@posting.price, producer_net)
        ProducerProductUnitCommission.create(user_id: @posting.user.id, product_id: @posting.product.id, unit_id: @posting.unit.id, commission: commission_factor)
      end
    end

    #first check to see if we have a commission set for this creation attempt
    commission = ProducerProductUnitCommission.where(user_id: posting_params[:user_id], product_id: posting_params[:product_id], unit_id: posting_params[:unit_id])

    if commission.count == 0
      #there is no commission set for this user/product/unit. tell the user and fail.
      if @posting.posting_recurrence.nil?
        @posting.build_posting_recurrence(posting_recurrence_params)
      end

      load_posting_choices
      flash.now[:danger] = "No commission is set for that product and unit. Please contact Farmer's Cellar to get a commission set."
      render 'new'
      return
    end

  	if @posting.save
      if @posting.live
        flash[:success] = "Your new posting is now live!"
      else
        flash[:info] = "Your posting was created but is not live as you specified during creation."
      end  	  
      redirect_to postings_path
    else      
      #if no recurrence is set, give farmer another chance to set that
      if @posting.posting_recurrence.nil?
        @posting.build_posting_recurrence(posting_recurrence_params)
      end

      load_posting_choices
      render 'new'
  	end

  end

  def edit
    #if an admin is doing this we want him to be able to edit it but if it's a farmer we want to put
    #contraints on. however, for now all we're implementing is the ability for farmer to switch between making the 
    #posting live or not live
    @posting = Posting.find(params[:id])        
    @posting_recurrence = @posting.posting_recurrence

    @upload = Upload.new

  end

  def update    

    @posting = Posting.find(params[:id])
    @posting_recurrence = @posting.posting_recurrence

    if @posting_recurrence && @posting_recurrence.on
      #check to see if the user just turned the recurrence off. if they did we need to persist that.

      if params[:posting][:posting_recurrence][:on] == "0"
        #user just turned off the recurrence so persist that to db
        @posting_recurrence.turn_off
        @posting_recurrence.save
      end

    end

    if @posting.update_attributes(posting_params_update)      
      flash[:success] = "Posting updated!"
      redirect_to current_user
    else
      flash.now[:danger] = "Posting not updated"
      @upload = Upload.new
      render 'edit'
    end

  end

  def show

    @posting = Posting.find(params[:id])
    if @posting.product.food_category
      @posting_food_category = @posting.product.food_category
    else
      @posting_food_category = FoodCategory.where(parent: nil).first
    end

    #we only want to show the user postings the are live and OPEN. if a producer has a one-time posting up, then if a customer tries to fetch the posting
    #after it's either unlive or not OPEN, we want to show them an error. however, if a customer tries to fetch an unlive/unOPENed posting it might be
    #due to them clicking on an older posting link from a postingrecurrence series. say, for example, i send someone a link to the current Pride & Joy
    #posting. But they don't get their email until next week. When they click on the link i'd like for them to see the current posting. so this logic
    #handles that as well.
    if !@posting.live || !@posting.state?(:OPEN)
      if @posting.posting_recurrence.nil?
        flash[:danger] = "Oops, that posting is no longer active"
        redirect_to food_category_path_helper(@posting_food_category)
        return
      else
        pr = @posting.posting_recurrence
        if pr.current_posting && pr.current_posting.live && pr.current_posting.state?(:OPEN)
          @posting = pr.current_posting          
        else
          flash[:danger] = "Oops, that posting is no longer active"
          redirect_to food_category_path_helper(@posting_food_category)
          return
        end
      end
    end

    @biggest_order_minimum_producer_net_outstanding = @posting.biggest_order_minimum_producer_net_outstanding

  end

  private

    def load_posting_choices
      @products = Product.all.order(:name)
      @units = Unit.all.order(:name)
      @delivery_dates = next_delivery_dates
      @producers = User.where(account_type: User.types[:PRODUCER]).order(:farm_name)
    end

    def posting_recurrence_params

      if !params.has_key?(:posting)
        return nil
      end

      if !params[:posting].has_key?(:posting_recurrence)
        return nil
      end

      pr_params = params.require(:posting).require(:posting_recurrence).permit(:frequency, :on)

      if pr_params[:frequency].to_i > PostingRecurrence.frequency[0][1]
        pr_params[:on] = true
      else
        pr_params[:on] = false
      end

      return pr_params
      
    end

    def posting_params

      posting = params.require(:posting).permit(
        :description_body,
        :price,
        :user_id,
        :product_id,
        :unit_id,
        :live,
        :delivery_date,
        :order_cutoff,
        :description,
        :price_body,
        :unit_body,
        :order_minimum_producer_net,
        :units_per_case,
        :product_id_code
        )      

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

      if posting[:unit_body].blank?
        posting[:unit_body] = nil
      end

      if posting[:price_body].blank?
        posting[:price_body] = nil
      end

      posting

    end

    def posting_params_update
      
      posting = params.require(:posting).permit(
        :description,
        :description_body,
        :price_body,
        :unit_body,
        :important_notes,
        :important_notes_body,
        :live
        )

      return posting

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