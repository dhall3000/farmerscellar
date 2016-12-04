class PostingsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :show, :edit, :update]
  before_action :redirect_to_root_if_not_producer, only: [:new, :create, :edit, :update]
  
  def new  	

    if params[:posting_id].nil?
      @posting = current_user.postings.new(live: true)                  
      #if you are doing dev work on the create method and want the new form autopopulated for sanity's sake, uncomment this line
      #@posting = Posting.new(live: true, delivery_date: Time.zone.now + 4.days, product_id: 8, quantity_available: 100, price: 2.50, user_id: User.find_by(name: "f4"), unit_category_id: UnitCategory.find_by(name: "Weight"), unit_kind_id: UnitKind.find_by(name: "Pound"), description: "best celery ever!")
    else
      posting_to_clone = Posting.find(params[:posting_id])
      @posting = posting_to_clone.dup
    end

    @posting.build_posting_recurrence
    load_posting_choices

  end

  def index

    if current_user.nil? || current_user.account_type == User.types[:CUSTOMER] || current_user.account_type == User.types[:PRODUCER]
      #for customers, we only want to pull postings whose delivery date is >= today and that are 'live'
      @postings = Posting.where("delivery_date >= ? and live = ?", Time.zone.today, true).order(delivery_date: :asc, id: :desc)
    elsif current_user.account_type == User.types[:ADMIN]
      #for admins, same thing but we want to see the unlive as well
      @postings = Posting.where("state <> ?", Posting.states[:CLOSED]).order(delivery_date: :asc, id: :desc)
    end

    return @postings

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
  end

  def update    
    @posting = Posting.find(params[:id])
    @posting_recurrence = @posting.posting_recurrence

    if @posting_recurrence != nil && @posting_recurrence.on
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
      render 'edit'
    end

  end

  def show
    @posting = Posting.find(params[:id])
  end

  private

    def load_posting_choices
      @products = Product.all.order(:name)
      @units = Unit.all
      @delivery_dates = next_delivery_dates
      @producers = User.where(account_type: User.types[:PRODUCER])
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
        :description,
        :quantity_available,
        :price,
        :user_id,
        :product_id,
        :unit_id,
        :live,
        :delivery_date,
        :order_cutoff,
        :product_attributes,
        :price_equivalency_description,
        :unit_equivalency_description,
        :product_identifier,
        :order_minimum_producer_net,
        :units_per_case
        )

      unit = Unit.all.find_by(id: posting[:unit_id])

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

      if posting[:unit_equivalency_description].blank?
        posting[:unit_equivalency_description] = nil
      end

      if posting[:price_equivalency_description].blank?
        posting[:price_equivalency_description] = nil
      end

      posting

    end

    def posting_params_update
      
      posting = params.require(:posting).permit(
        :description,
        :quantity_available,
        :price,
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