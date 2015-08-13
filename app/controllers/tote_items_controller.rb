class ToteItemsController < ApplicationController
  def index
    if logged_in?
      @tote_items = current_user_current_tote_items
      @total_amount = total_cost_of_tote_items(@tote_items)      
    end
  end

  def show
  end

  def new
    @tote_item = ToteItem.new
  end

  def create    
    @tote_item = ToteItem.new(tote_item_params)
    if @tote_item.save
      flash[:success] = "Item saved to your shopping tote!"
      redirect_to tote_items_path
    else
      flash[:danger] = "Item not saved to your shopping tote. If you continue to experience this problem please contact Farmer's Cellar support."
    end
  end

  def next
    #TODO: this action should only be visible to an admin.
    #this page is for pulling the next tote_item off the queue to fill when sorters are processing a delivery
    #render 'next'

    #get the posting_id
    #if we also have a ti id, flip it's state to FILLED
    #get the next ti id to fill

    posting_id = nil
    
    if params[:tote_item] == nil
      #TODO: we have an error here we should handle gracefully
    else
      if params[:tote_item][:posting_id] == nil
        #TODO: we have an error here we should handle gracefully
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

    #DESCRIPTION: the intent is for use by shopping tote editing feature enabling user to remove items from their tote
    ti = ToteItem.find_by_id(params[:id])

    if ti == nil
      flash[:danger] = "Shopping tote item not deleted."
    else
      if ti.status == ToteItem.states[:ADDED] || ti.status == ToteItem.states[:AUTHORIZED]
        ti.update(status: ToteItem.states[:REMOVED])
        flash[:success] = "Shopping tote item removed."
      else
        flash[:danger] = "This item is not removable, probably because it is already 'committed'. Please see our policies regarding committed shopping tote items. Shopping tote item not deleted."        
      end
    end
    
    redirect_to tote_items_path
  end

  private
    def tote_item_params
      params.require(:tote_item).permit(:quantity, :price, :status, :posting_id, :user_id)
    end

end
