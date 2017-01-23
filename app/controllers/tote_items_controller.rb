class ToteItemsController < ApplicationController

  before_action :correct_user,   only: [:destroy, :pout]
  before_action :logged_in_user, only: [:index, :create, :destroy, :pout]

  def index

    @dropsite = nil

    if current_user.dropsites.any?        
      @dropsite = current_user.dropsite
    else
      #here the logic is if we only have one dropsite (which is the case for awhile after initial business launch)
      #then we don't need to ask user to specify dropsite. Just assign the current dropsite (for this checkout) to
      #be the only dropsite and proceed
      if Dropsite.count == 1
        @dropsite = Dropsite.order("dropsites.id").first
        current_user.set_dropsite(@dropsite)
      end
    end

    @rtba = current_user.get_active_rtba
    @items_total_gross = 0    
    template = ''

    if params[:orders]
      #user wants to see their orders      
      @tote_items = authorized_items_for(current_user)
      @subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = false, kind = Subscription.kinds[:NORMAL])[:authorized]
      template = 'tote_items/orders'      
    else
      #user wants to see their shopping tote
      @tote_items = unauthorized_items_for(current_user)
      @subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true, kind = Subscription.kinds[:NORMAL])[:unauthorized]      
      @recurring_orders = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true)[:unauthorized]      
      template = 'tote_items/tote'
    end

    if @tote_items
      @tote_items = @tote_items.joins(:posting).order("postings.delivery_date")
      @items_total_gross = get_gross_tote(@tote_items)
    end

    render template    

  end

  def new

    @posting = Posting.find(params[:posting_id])

    if !@posting
      flash[:danger] = "Oops, no such posting"
      redirect_to postings_path
      return
    end

    #we only want to show the user postings the are live and OPEN. if a producer has a one-time posting up, then if a customer tries to fetch the posting
    #after it's either unlive or not OPEN, we want to show them an error. however, if a customer tries to fetch an unlive/unOPENed posting it might be
    #due to them clicking on an older posting link from a postingrecurrence series. say, for example, i send someone a link to the current Pride & Joy
    #posting. But they don't get their email until next week. When they click on the link i'd like for them to see the current posting. so this logic
    #handles that as well.
    if !@posting.live || !@posting.state?(:OPEN)
      if @posting.posting_recurrence.nil?
        flash[:danger] = "Oops, that posting is no longer active"
        redirect_to postings_path
        return
      else
        pr = @posting.posting_recurrence
        if pr.current_posting && pr.current_posting.live && pr.current_posting.state?(:OPEN)
          @posting = pr.current_posting          
        else
          flash[:danger] = "Oops, that posting is no longer active"
          redirect_to postings_path
          return
        end
      end
    end

    @sanitized_producer_url = @posting.user.website
    if @sanitized_producer_url != nil
      @sanitized_producer_url = url_with_protocol(@sanitized_producer_url)
    end

    @account_on_hold = account_on_hold
    @tote_item = ToteItem.new
    @biggest_order_minimum_producer_net_outstanding = @posting.biggest_order_minimum_producer_net_outstanding

  end

  def create

    #if user's account is on hold we don't want to allow them to add tote items    
    if account_on_hold
      flash[:danger] = "Your account is on hold. Please contact Farmer's Cellar."
      redirect_to(root_url)
      return
    end

    @posting_id = params[:posting_id].to_i
    @quantity = params[:quantity].to_i
    if params[:frequency].blank?
      @frequency = nil
    else
      @frequency = params[:frequency].to_i
    end    

    posting = Posting.find_by(id: @posting_id)

    if posting.nil?
      flash[:danger] = "Oops, please try that again"
      redirect_to postings_path
      return
    end
    
    if !posting.live
      flash[:danger] = "Oops, please try adding that again"
      redirect_to food_category_path_helper(posting.product.food_category)
      return
    end

    if posting.posting_recurrence.nil? || !posting.posting_recurrence.on
      #one and done. no recurrence so just create a single tote item and carry on
      @tote_item = create_tote_item(posting, @quantity)
      return
    end

    if @frequency
      if @frequency > 0
      else        
        @tote_item = create_tote_item(posting, @quantity)
        return
      end
    else
      #try to upsell a subscription
      render 'how_often'
    end    

  end

  def create_old

    #if user's account is on hold we don't want to allow them to add tote items    
    if account_on_hold
      flash[:danger] = "Your account is on hold. Please contact Farmer's Cellar."
      redirect_to(root_url)
      return
    end

    @tote_item = ToteItem.new(tote_item_params)
    @tote_item.user_id = current_user.id
    @posting = Posting.find(@tote_item.posting_id)
    @tote_item.price = @posting.price

    if !correct_user_create(@tote_item)
      redirect_to(root_url)
      return
    end

    if !@tote_item.posting.live
      flash[:danger] = "Oops, please try adding that again"
      redirect_to postings_path
    elsif @tote_item.save
      if @tote_item.posting.posting_recurrence && @tote_item.posting.posting_recurrence.on
        #this posting is subscribable. attempt subscription upsell.
        redirect_to new_subscription_path(tote_item_id: @tote_item.id)
        return
      else
        flash[:success] = "Tote item added"
        if @posting.product.food_category
          redirect_to postings_path(food_category: @posting.product.food_category.name)
        else
          redirect_to postings_path
        end        
        return        
      end
    else
      flash.now[:danger] = "Item not added to tote. See errors below."
      @sanitized_producer_url = @posting.user.website
      if @sanitized_producer_url != nil
        @sanitized_producer_url = url_with_protocol(@sanitized_producer_url)
      end

      @account_on_hold = account_on_hold
      @biggest_order_minimum_producer_net_outstanding = @posting.biggest_order_minimum_producer_net_outstanding
      render 'new'
    end
  end

  def pout

    @tote_item = ToteItem.find_by(id: params[:id])

    if @tote_item.nil?
      #this should be impossible. email admin.
      AdminNotificationMailer.general_message("unknown problem. pout message didn't display", "user id #{current_user.id.to_s} should have seen the pout page but @tote_item was nil. params[:id] = #{params[:id].to_s}").deliver_now
      flash.discard
      redirect_to postings_path
      return    
    end

    @additional_units_required_to_fill_my_case = @tote_item.additional_units_required_to_fill_my_case
    @biggest_order_minimum_producer_net_outstanding = @tote_item.posting.biggest_order_minimum_producer_net_outstanding

    @posting = @tote_item.posting
    @will_partially_fill = @tote_item.will_partially_fill?
    @expected_fill_quantity = @tote_item.expected_fill_quantity

    #if order minimums aren't met there's not going to be any filling whatsoever
    if @biggest_order_minimum_producer_net_outstanding > 0
      @expected_fill_quantity = 0
      @will_partially_fill = false
    end

    if @additional_units_required_to_fill_my_case < 1 && @biggest_order_minimum_producer_net_outstanding <= 0
      AdminNotificationMailer.general_message("pout message problem", "@additional_units_required_to_fill_my_case = #{@additional_units_required_to_fill_my_case.to_s}. @biggest_order_minimum_producer_net_outstanding = #{@biggest_order_minimum_producer_net_outstanding.to_s}. user id #{current_user.id.to_s} should have seen the pout page? @tote_item.id #{@tote_item.id.to_s}.").deliver_now
      flash.discard
      redirect_to postings_path
      return
    end

    @account_on_hold = account_on_hold
    @back_link = request.referer

    case request.referer
    when new_tote_item_url(posting_id: @tote_item.posting.id.to_s)
      @back_link = postings_path
      @back_link_text = "continue shopping"
    when tote_items_url
      @back_link_text = "shopping tote"
    when tote_items_url(orders: true)
      @back_link_text = "current orders"
    else
      @back_link = nil
      @back_link_text = nil
    end

  end

  def destroy

    #notes for future implementation:
    #after an auth'd item is removed from the toteitem, do we nuke the auth? ppal nukes the entire auth if we do.
    #answer: when an item gets removed we get its authorization. if for this auth there still exists any toteitems in states AUTHORIZED: 1, COMMITTED: 2, FILLED then we do nothing because this auth is still needed for those items.
    #however, if there are no items remaining in any of the above-mentioned states we can cancel the remaining authorized balance, per the following:
    #https://developer.paypal.com/docs/classic/paypal-payments-standard/integration-guide/authcapture/
    #Lower Capture Amount
    #You complete a void on the funds remaining on the authorization. 

    #DESCRIPTION: the intent is for use by shopping tote editing feature enabling user to remove items from their tote
    @referer = request.referer || tote_items_path(orders: true)
    ti = ToteItem.find_by_id(params[:id])

    if ti == nil
      flash[:danger] = "Shopping tote item not deleted."
    else

      if ti.state?(:COMMITTED)
        flash[:danger] = "This item is not removable because it is already 'committed'. Please see 'Order Cancellation' on the 'How it Works' page. Shopping tote item not deleted."
      else
        ti.transition(:customer_removed)        
        if ti.state?(:REMOVED)

          flash_text = "#{ti.posting.product.name} for #{ti.posting.delivery_date.strftime("%A %B %d")} delivery canceled"

          if ti.subscription && ti.subscription.on && !ti.subscription.paused && ti.subscription.kind?(:NORMAL)

            flash.now[:success] = flash_text
            @subscription = ti.subscription
            @product_name = ti.posting.product.name
            @tote_item = ti            
            ti.subscription.create_skip_date(ti)
            render 'tote_items/subscription_action'

            return

          else
            flash[:success] = flash_text
          end
          
        else
          flash[:danger] = "This item could not be removed. Please contact Farmer's Cellar for help."
        end
      end

      if ti.roll_until_filled?
        ti.subscription.turn_off
      end
            
    end
    
    redirect_to @referer

  end

  private
    def tote_item_params
      params.require(:tote_item).permit(:quantity, :posting_id)
    end

    def create_tote_item(posting, quantity)
      
      tote_item = ToteItem.new(posting: posting, quantity: quantity)
      tote_item.price = posting.price
      tote_item.user = current_user

      if tote_item.save
        flash[:success] = "Tote item added"
      else
        flash[:danger] = "Tote item not added. Please contact us so we can help you."
      end
      
      redirect_to food_category_path_helper(posting.product.food_category)

      return tote_item

    end

    def account_on_hold

      if current_user.nil?
        return false
      end

      return current_user.account_currently_on_hold?

    end

    # Confirms the correct user.
    def correct_user

      #@user = User.find(params[:id])
      #redirect_to(root_url) unless current_user?(@user)
      ti = ToteItem.find_by_id(params[:id])

      if ti == nil
        redirect_to(root_url)
        return
      end

      user = User.find(ti.user_id)

      if user == nil
        redirect_to(root_url)
        return
      end

      if !current_user?(user)
        redirect_to(root_url)
        return
      end        

    end

    def correct_user_create(tote_item)

      if tote_item == nil
        return false
      end

      user = User.find_by_id(tote_item.user_id)

      if user == nil        
        return false
      end

      if current_user?(user)        
        return true
      else
        return false
      end        
    end

end
