class PostingsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update, :delivery_date_range_selection_got_it]
  before_action :redirect_to_root_if_not_producer, only: [:new, :create, :edit, :update]
  before_action :correct_producer, only: [:edit, :update]
  before_action :get_posting, only: [:edit, :update, :show]
  
  def new  	

    posting_to_clone = nil

    if params[:posting_id]
      #we're copying a posting
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup

      if spoofing?
        @producer_net = posting_to_clone.producer_net_unit
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

    @food_category = FoodCategory.includes(:parent, children: :uploads).where(name: params[:food_category]).first
 
    #this is midnight the first day of the new week's cycle
    next_week_start = start_of_next_week    
    next_week_end = next_week_start + 7.days
            
    if @food_category
      
      products = @food_category.products

      @this_weeks_postings = get_postings(products, Time.zone.now.midnight, next_week_start)
      @next_weeks_postings = get_postings(products, next_week_start, next_week_end)
      @future_postings = get_postings(products, next_week_end, next_week_end + 10.years)

    else      
      redirect_to root_path
    end

  end

  def delivery_date_range_selection_got_it

    if current_user
      if current_user.got_it.nil?
        current_user.create_got_it
      end
      current_user.got_it.update(delivery_date_range_selection: true)
    end

    redirect_to request.referer

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

    if !spoofing?
      if posting_params[:producer_net_unit].to_f == 0
        @posting.producer_net_unit = get_producer_net_unit(0.1, @posting.price)
      end
    end

  	if @posting.save
      if @posting.live
        flash[:success] = "Your new posting is now live!"
      else
        flash[:info] = "Your posting was created but is not live as you specified during creation."
      end

      if !spoofing?
        AdminNotificationMailer.general_message("producer just created his own posting", "producer has no way of specifying producer_net_unit so we set it for them at our standard commission. Make sure that value is set. Posting id is #{@posting.id.to_s}").deliver_now
      end

      redirect_to postings_path
    else      
      #if no recurrence is set, give farmer another chance to set that
      if @posting.posting_recurrence.nil?
        @posting.build_posting_recurrence(posting_recurrence_params)
      end

      load_posting_choices
      flash.now[:danger] = "Posting not saved"
      render 'new'
  	end

  end

  def edit
    #if an admin is doing this we want him to be able to edit it but if it's a farmer we want to put
    #contraints on. however, for now all we're implementing is the ability for farmer to switch between making the 
    #posting live or not live    
    @posting_recurrence = @posting.posting_recurrence

    @upload = Upload.new

  end

  def update    
    
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
          redirect_to pr.current_posting
          return
        else
          flash[:danger] = "Oops, that posting is no longer active"
          redirect_to food_category_path_helper(@posting_food_category)
          return
        end
      end
    end

    @links = FoodCategoriesController.helpers.get_top_down_ancestors(@posting_food_category, include_self = true)    
    @biggest_order_minimum_producer_net_outstanding = @posting.biggest_order_minimum_producer_net_outstanding

  end

  private

    def get_posting
      @posting = Posting.includes(:unit, :user, :uploads, :posting_recurrence, product: :food_category).where(id: params[:id]).first

      if @posting.nil?
        flash[:danger] = "Oops, that posting doesn't exist"
        redirect_to postings_path
      end
    end  

    def correct_producer

      @posting = Posting.find_by(id: params[:id])

      if @posting.nil?
        return
      end

      if current_user.id != @posting.user.id
        flash[:danger] = "That posting doesn't belong to you"
        redirect_to root_path
      end
      
    end  

    def get_postings(products, start_time, end_time, limit = nil)    

      return_postings = Posting.includes(:user, :product, :unit).where(product: products).where("delivery_date >= ? and delivery_date < ? and live = ? and postings.state = ?", start_time, end_time, true, Posting.states[:OPEN])

      if limit
        #if we're going to limit the postings it's because we think we have too many. if we have too many
        #then let's only show the postings that have pics, hence the .joins(:uploads)
        return_postings = return_postings.joins(:uploads).distinct.limit(limit)
      end    
      
      return return_postings

    end

    def load_posting_choices
      @products = Product.all.order(:name)
      @units = Unit.all.order(:name)      
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
        :product_id_code,
        :producer_net_unit,
        :refundable_amount_unit_producer_to_fc
        )      

      posting[:price] = posting[:price].to_f.round(2)
      posting[:producer_net_unit] = posting[:producer_net_unit].to_f.round(2)

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

end