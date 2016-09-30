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

    @tote_items = current_user_current_tote_items

    if @tote_items.nil?
      @total_amount_to_authorize = 0
    else
      @tote_items = @tote_items.order("postings.delivery_date")
      @total_amount_to_authorize = get_gross_tote(@tote_items.where(state: ToteItem.states[:ADDED]))
    end

    @rtba = current_user.get_active_rtba
    @subscriptions = get_active_subscriptions_for(current_user)
    @provide_guest_checkout_option = !@rtba && !@subscriptions      

  end

  def new

    @posting = Posting.find(params[:posting_id])

    if !@posting || !@posting.live
      flash[:danger] = "Oops, please try adding that again"
      redirect_to postings_path
      return
    end

    @sanitized_producer_url = @posting.user.website
    if @sanitized_producer_url != nil
      @sanitized_producer_url = url_with_protocol(@sanitized_producer_url)
    end

    @account_on_hold = account_on_hold
    @tote_item = ToteItem.new

  end

  def create

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

        additional_units_required_to_fill_my_case = @tote_item.additional_units_required_to_fill_my_case

        if additional_units_required_to_fill_my_case == 0
          flash[:success] = "Item added to tote."
          redirect_to postings_path
          return
        else

          if @tote_item.will_partially_fill?
            flash_message = "Tote item created but currently will only partially ship. See below."
          else
            flash_message = "Tote item created but currently won't ship. See below."
          end

          flash[:danger] = flash_message
          redirect_to tote_items_pout_path(id: @tote_item.id)
          
          return

        end
        
      end

    else
      flash.now[:danger] = "Item not added to tote. See errors below."
      @sanitized_producer_url = @posting.user.website
      if @sanitized_producer_url != nil
        @sanitized_producer_url = url_with_protocol(@sanitized_producer_url)
      end

      @account_on_hold = account_on_hold
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

    @posting = @tote_item.posting
    @additional_units_required_to_fill_my_case = @tote_item.additional_units_required_to_fill_my_case
    @will_partially_fill = @tote_item.will_partially_fill?

    if @additional_units_required_to_fill_my_case < 1
      AdminNotificationMailer.general_message("unknown problem. pout message action called but @additional_units_required_to_fill_my_case < 1", "user id #{current_user.id.to_s} should have seen the pout page. @tote_item.id #{@tote_item.id.to_s}. @additional_units_required_to_fill_my_case = #{@additional_units_required_to_fill_my_case.to_s}").deliver_now
      flash.discard
      redirect_to postings_path
      return
    end

    @account_on_hold = account_on_hold

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

          if ti.subscription && ti.subscription.on && !ti.subscription.paused

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
            
    end
    
    redirect_to tote_items_path
  end

  private
    def tote_item_params
      params.require(:tote_item).permit(:quantity, :posting_id)
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
