class ToteItemsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: :next
  before_action :correct_user,   only: [:destroy]

  def index
    if logged_in?

      @dropsite = nil

      if current_user.dropsites.any?        
        @dropsite = Dropsite.find(current_user.dropsites.joins(:user_dropsites).order('user_dropsites.created_at').last.id)
      else
        #here the logic is if we only have one dropsite (which is the case for awhile after initial business launch)
        #then we don't need to ask user to specify dropsite. Just assign the current dropsite (for this checkout) to
        #be the only dropsite and proceed
        if Dropsite.count == 1
          @dropsite = Dropsite.first
          current_user.dropsites << @dropsite
          current_user.save
        end
      end

      @tote_items = current_user_current_tote_items

      if @tote_items == nil
        @total_amount_to_authorize = 0
      else
        @total_amount_to_authorize = get_gross_tote(@tote_items.where(status: ToteItem.states[:ADDED]))      
      end

      @rtba = current_user.get_active_rtba
      @subscriptions = get_subscriptions_from(@tote_items)
      @provide_guest_checkout_option = !@rtba && !@subscriptions      

    end
  end

  def show
  end

  def url_with_protocol(url)
    /^http/i.match(url) ? url : "http://#{url}"
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

    if !correct_user_create(@tote_item)
      redirect_to(root_url)
      return
    end

    #is the user trying to create a new subscription?
    if params[:tote_item][:subscription_frequency].to_i > 0

      #is there a posting? is the posting live? does the posting have a recurrence? is the posting recurrence turned on?
      if @tote_item.posting != nil && @tote_item.posting.live && @tote_item.posting.posting_recurrence != nil && @tote_item.posting.posting_recurrence.on
        
        frequency = params[:tote_item][:subscription_frequency].to_i      
        @subscription = Subscription.new(
          frequency: frequency,
          on: true,
          user_id: @tote_item.user_id,
          posting_recurrence_id: @tote_item.posting.posting_recurrence.id,
          quantity: @tote_item.quantity
          )

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

  def next
    #this page is for pulling the next tote_item off the queue to fill when sorters are processing a delivery
    #render 'next'

    #get the posting_id
    #if we also have a ti id, flip it's state to FILLED
    #get the next ti id to fill

    #this is so that we can use the test page to inspect the view
    if params.has_key?("test")

      @tote_item = ToteItem.new
      @tote_item.user_id = 17
      @tote_item.quantity = 100

      @tote_item.id = 1
      @tote_item.price = 2.25
      @tote_item.status = 7
      @tote_item.posting_id = 11

      return

    end

    @errors = []
    posting_id = nil

    if params[:tote_item] == nil
      @errors << "not sure how this happened but we just hit 'impossible' logic in tote_items_controller.rb: params[:tote_item] == nil"
    else
      if params[:tote_item][:posting_id] == nil
        @errors << "not sure how this happened but we just hit 'impossible' logic in tote_items_controller.rb: params[:tote_item][:posting_id] == nil"
      else
        posting_id = params[:tote_item][:posting_id]
        @tote_item = ToteItem.dequeue(posting_id)
        if params[:tote_item][:id] != nil
          #stamp this incoming tote_item as 'FILLED'
          ToteItem.status(params[:tote_item][:id], ToteItem.states[:FILLED])
        end
      end
    end    
  end

  def edit
  end

  def update
  end

  def destroy

    #notes for future implementation:
    #after an auth'd item is removed from the toteitem, do we nuke the auth? ppal nukes the entire auth if we do.
    #answer: when an item gets removed we get its authorization. if for this auth there still exists any toteitems in states AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED then we do nothing because this auth is still needed for those items.
    #however, if there are no items remaining in any of the above-mentioned states we can cancel the remaining authorized balance, per the following:
    #https://developer.paypal.com/docs/classic/paypal-payments-standard/integration-guide/authcapture/
    #Lower Capture Amount
    #You complete a void on the funds remaining on the authorization. 


    #DESCRIPTION: the intent is for use by shopping tote editing feature enabling user to remove items from their tote
    ti = ToteItem.find_by_id(params[:id])

    if ti == nil
      flash[:danger] = "Shopping tote item not deleted."
    else
      if ti.status == ToteItem.states[:ADDED] || ti.status == ToteItem.states[:AUTHORIZED]
        ti.update(status: ToteItem.states[:REMOVED])
        flash[:success] = "Shopping tote item removed."
      else
        flash[:danger] = "This item is not removable because it is already 'committed'. Please see 'Commitment Zone' on the 'How it Works' page. Shopping tote item not deleted."
      end
    end
    
    redirect_to tote_items_path
  end

  private
    def tote_item_params
      params.require(:tote_item).permit(:quantity, :price, :status, :posting_id, :user_id)
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
