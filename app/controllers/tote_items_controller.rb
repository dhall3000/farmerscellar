class ToteItemsController < ApplicationController
  before_action :correct_user,   only: [:destroy]
  before_action :logged_in_user

  def index

    @dropsite = nil

    if current_user.dropsites.any?        
      @dropsite = current_user.dropsite
    else
      #here the logic is if we only have one dropsite (which is the case for awhile after initial business launch)
      #then we don't need to ask user to specify dropsite. Just assign the current dropsite (for this checkout) to
      #be the only dropsite and proceed
      if Dropsite.count == 1
        @dropsite = Dropsite.first
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
    @subscriptions = get_subscriptions_from(@tote_items)
    @provide_guest_checkout_option = !@rtba && !@subscriptions      

  end

  def new
    posting = Posting.find(params[:posting_id])
    @sanitized_producer_url = posting.user.website
    if @sanitized_producer_url != nil
      @sanitized_producer_url = url_with_protocol(@sanitized_producer_url)
    end

    @account_on_hold = account_on_hold
    @tote_item = ToteItem.new

    if !posting.posting_recurrence.nil? && posting.posting_recurrence.subscribable?
      @subscription = Subscription.new(frequency: 0, on: true, user_id: current_user.id, posting_recurrence_id: posting.posting_recurrence.id)
    end

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
    posting = Posting.find_by(@tote_item.posting_id)
    @tote_item.price = posting.price

    if !correct_user_create(@tote_item)
      redirect_to(root_url)
      return
    end

    #is the user trying to create a new subscription?
    if params[:tote_item][:subscription_frequency].to_i > 0

      #is there a posting? is the posting live? does the posting have a recurrence? is the posting recurrence turned on?
      if @tote_item.posting != nil && @tote_item.posting.live && @tote_item.posting.posting_recurrence != nil && @tote_item.posting.posting_recurrence.on
        
        frequency = params[:tote_item][:subscription_frequency].to_i
        new_subscription_params = {
          frequency: frequency,
          on: true,
          user_id: current_user.id,
          quantity: @tote_item.quantity          
        }

        @subscription = @tote_item.posting.posting_recurrence.subscriptions.create(new_subscription_params)

        if @subscription.save
          @subscription.generate_next_tote_item
          flash[:success] = "New subscription created."
          redirect_to postings_path
        else
          flash.now[:danger] = "Subscription not saved. See errors below."
          render 'new'
        end

      else
        #we need a live posting and a 'on' posting recurrence. that isn't the case to inform the user constructively.
        flash[:danger] = "Oops, it appears that posting is no longer live. Subscription not created."
        redirect_to postings_path
      end

    elsif !@tote_item.posting.live
      flash[:danger] = "Oops, it appears that posting is no longer live. Item not created."
      redirect_to postings_path
    elsif @tote_item.save
      flash[:success] = "Item saved to shopping tote."
      redirect_to postings_path
    else
      flash.now[:danger] = "Item not saved to shopping tote. See errors below."
      render 'new'
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
    ti = ToteItem.find_by_id(params[:id])

    if ti == nil
      flash[:danger] = "Shopping tote item not deleted."
    else

      if ti.state?(:COMMITTED)
        flash[:danger] = "This item is not removable because it is already 'committed'. Please see 'Commitment Zone' on the 'How it Works' page. Shopping tote item not deleted."
      else
        ti.transition(:customer_removed)        
        if ti.state?(:REMOVED)
          flash[:success] = "Shopping tote item removed."
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
      
      if current_user.account_states == nil || !current_user.account_states.any?
        account_on_hold = false
      else
        account_on_hold = current_user.user_account_states.order(:created_at).last.account_state.state == AccountState.states[:HOLD]
      end

      return account_on_hold

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
