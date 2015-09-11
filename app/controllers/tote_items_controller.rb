class ToteItemsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: :next
  before_action :correct_user,   only: [:destroy]

  def index
    if logged_in?
      @tote_items = current_user_current_tote_items
      if @tote_items == nil
        @total_amount_to_authorize = 0
      else
        @total_amount_to_authorize = total_cost_of_tote_items(@tote_items.where(status: ToteItem.states[:ADDED]))      
      end
    end
  end

  def show
  end

  def new
    @tote_item = ToteItem.new
  end

  def create    
    @tote_item = ToteItem.new(tote_item_params)

    if !correct_user_create(@tote_item)
      redirect_to(root_url)
      return
    end

    if @tote_item.save
      flash.now[:success] = "Item saved to your shopping tote!"
    else
      flash.now[:danger] = "Item not saved to your shopping tote."
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
