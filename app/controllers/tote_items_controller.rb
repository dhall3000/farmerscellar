class ToteItemsController < ApplicationController

  before_action :correct_user,   only: [:destroy, :pout]
  before_action :logged_in_user

  def pickup

    if Rails.env.development?
      if current_user.tote_items.where(state: ToteItem.states[:FILLED]).count == 0
        ToteItem.create(user: current_user, price: Posting.first.price, posting: Posting.first, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
        ToteItem.create(user: current_user, price: Posting.second.price, posting: Posting.second, quantity: 2, quantity_filled: 1, state: ToteItem.states[:FILLED])
        ToteItem.create(user: current_user, price: Posting.third.price, posting: Posting.third, quantity: 3, quantity_filled: 0, state: ToteItem.states[:NOTFILLED])
        ToteItem.create(user: current_user, price: Posting.fourth.price, posting: Posting.fourth, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
        ToteItem.create(user: current_user, price: Posting.fifth.price, posting: Posting.fifth, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
      end

      if !current_user.dropsites.any?        
        current_user.set_dropsite(Dropsite.first)
      end

      @tote_items = current_user.tote_items.includes(:posting).last(5)
    else
      @tote_items = current_user.tote_items_to_pickup
    end
    
  end

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

    if params[:calendar]

      @tote_items_by_week = []      
      tote_items = ToteItem.calendar_items_displayable(current_user)
      @first_future_item = future_items(tote_items).first

      if tote_items.any?
        calendar_start = tote_items.first.posting.delivery_date
        calendar_end = tote_items.last.posting.delivery_date

        delivery_date = calendar_start        

        while delivery_date <= calendar_end

          pickup_range = pickup_range_for(delivery_date)
          tote_items_for_range = tote_items.where("postings.delivery_date >= ? and postings.delivery_date <= ?", pickup_range[0], pickup_range[1])

          if tote_items_for_range.any?
            @tote_items_by_week << {start: pickup_range[0], end: pickup_range[1], tote_items: tote_items_for_range}
          end

          delivery_date += 7.days

        end        

      end
      render 'tote_items/calendar'
      return
    end

    @rtba = current_user.get_active_rtba
    @items_total_gross = 0    
    template = ''

    if params[:orders]
      #user wants to see their orders      
      @tote_items = authorized_items_for(current_user).joins(:posting).order("postings.delivery_date")
      @subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = false, kind = Subscription.kinds[:NORMAL])[:authorized]      
      @items_total_gross = get_gross_tote(@tote_items)
      template = 'tote_items/orders'      
    elsif params[:history]
      if Rails.env.development?
        if current_user.tote_items.where(state: ToteItem.states[:FILLED]).count == 0
          ToteItem.create(user: current_user, price: Posting.first.price, posting: Posting.first, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
          ToteItem.create(user: current_user, price: Posting.second.price, posting: Posting.second, quantity: 2, quantity_filled: 1, state: ToteItem.states[:FILLED])
          ToteItem.create(user: current_user, price: Posting.third.price, posting: Posting.third, quantity: 3, quantity_filled: 0, state: ToteItem.states[:NOTFILLED])
          ToteItem.create(user: current_user, price: Posting.fourth.price, posting: Posting.fourth, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
          ToteItem.create(user: current_user, price: Posting.fifth.price, posting: Posting.fifth, quantity: 1, quantity_filled: 1, state: ToteItem.states[:FILLED])
        end

        if !current_user.dropsites.any?        
          current_user.set_dropsite(Dropsite.first)
        end

        @tote_items = current_user.tote_items.includes(:posting).paginate(:page => params[:page], :per_page => 2)
      else        
        @tote_items = current_user.tote_items.joins(:posting).where(state: ToteItem.states[:FILLED]).paginate(:page => params[:page], :per_page => 12).order("postings.delivery_date desc")
      end
      template = 'tote_items/history'
    else
      #user wants to see their shopping tote
      @tote_items = unauthorized_items_for(current_user).joins(:posting).order("postings.delivery_date")
      @subscriptions = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true, kind = Subscription.kinds[:NORMAL])[:unauthorized]      
      @recurring_orders = get_active_subscriptions_by_authorization_state(current_user, include_paused_subscriptions = true)[:unauthorized]            
      @items_total_gross = get_gross_tote(@tote_items)
      template = 'tote_items/tote'
    end

    render template    

  end

  def create

    if params[:frequency].blank?
      @frequency = nil
    else
      @frequency = params[:frequency].to_i
    end    

    posting_id = params[:posting_id].to_i
    @posting = Posting.find_by(id: posting_id)

    if @posting.nil?
      flash[:danger] = "Oops, please try that again"
      redirect_to postings_path
      return
    end
    
    if !@posting.live
      flash[:danger] = "Oops, please try adding that again"
      redirect_to food_category_path_helper(@posting.product.food_category)
      return
    end

    #if user's account is on hold we don't want to allow them to add tote items    
    if account_on_hold
      flash[:danger] = "Your account is on hold. Please contact Farmer's Cellar."
      redirect_to posting_path(@posting)
      return
    end

    @quantity = params[:quantity].to_i
    if @quantity < 1
      flash[:danger] = "Invalid quantity"
      redirect_to posting_path(@posting)
      return
    end

    if !@posting.subscribable?
      #one and done. no recurrence so just create a single tote item and carry on
      @tote_item = create_tote_item(@posting, @quantity)
      return
    end

    if @frequency && @frequency < 1
      @tote_item = create_tote_item(@posting, @quantity)
      return      
    end    

    #############business bootstrapping code#############
    #this functionality is intended for FC's bootstrap launching phase. that is, right now it's 12/16/16 and we have products with $1000 OM
    #and very few customers. we want to accrue customers over a long period of time to hit that OM so we want to steer people away from
    #the vanilla Just Once option because almost certainly they won't get filled and won't come back. instead, for now, we'll remove that
    #option so the only option they have left is Just Once (Roll Until Filled). hopefully more people will select this so that we can
    #hit the OM. so, if we ever succeed, yank this functionality cause it won't matter once fc sales are $10M USD / month. for example.
    biggest_order_minimum_producer_net_outstanding = @posting.biggest_order_minimum_producer_net_outstanding

    if biggest_order_minimum_producer_net_outstanding.nil?
      biggest_order_minimum_producer_net_outstanding = 0
    end

    case_constraints_met = true    

    if @posting.units_per_case.to_i > 1 && @posting.total_quantity_ordered < @posting.units_per_case.to_i
      case_constraints_met = false
    end

    #NOTE: Change of plans. the following line is what we used to use. it said to show the vanilla just once if order min and case constraint were met. but read below for how this
    #caused an issue
    #@display_vanilla_just_once_option = biggest_order_minimum_producer_net_outstanding == 0 && case_constraints_met
    
    #make it so that vanilla Just Once never appears for now. there's very little positive value to leaving it there and there's significant adverse effect. here's why:
    #say on week 1 we get beyond the order min by selling RTF orders. since the RTF is really a subscription it will generate a new tote item as soon as we hit the order
    #cutoff for week 1. once all these RTFs generate their item for week 2 that also will triger the order min to be hit which will trigger the vanilla Just Once button to appear.
    #so then if a bunch of people sign up for Just Once (vanilla) then once week 1 delivery happens all those week 1 RTF orders for week 2 will cancel sending us back down
    #below the order min for week 2. so then the vanilla Just Once'ers won't get filled and they won't roll so we'll have lost sales.
    @display_vanilla_just_once_option = false
    #when yanking this code, fix the tests by uncommenting these test lines:
    #assert_select 'div div div form input[type=?][value=?]', "submit", "Just once", 1
    #############business bootstrapping code#############

    @subscription_create_options = @posting.posting_recurrence.subscription_create_options
    @links = FoodCategoriesController.helpers.get_top_down_ancestors(@posting.food_category, include_self = true)
    @links << {text: @posting.product.name, path: posting_path(@posting)}

    #try to upsell a subscription
    render 'how_often'

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
    when posting_url(@tote_item.posting)
      @back_link = posting_path(@tote_item.posting)
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
        flash[:danger] = "Order not canceled. Order Cutoff was #{ti.posting.order_cutoff.strftime("%a %b %e at %l:%M %p")}. Please see 'Order Cancellation' on the 'How Things Works' page for more details."
      else
        ti.transition(:customer_removed)        
        if ti.state?(:REMOVED)

          flash_text = "#{ti.posting.product.name} canceled"

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
      
      tote_item = ToteItem.new(posting: posting, quantity: quantity, state: ToteItem.states[:ADDED])
      tote_item.price = posting.price
      tote_item.user = current_user

      if tote_item.save
        flash[:success] = "Tote item added"
        redirect_to food_category_path_helper(posting.product.food_category)
      else
        flash[:danger] = "Tote item not added"
        redirect_to posting_path(posting)
      end      

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
