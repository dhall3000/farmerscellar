class ToteItemsController < ApplicationController
  def index
    #@tote_items = ToteItem.includes(posting: [:user, :product]).where(user_id: current_user.id)    
  end

  def show
  end

  def new
    @tote_item = ToteItem.new
  end

  def create    
    @tote_item = ToteItem.new(tote_item_params)
    if @tote_item.save
      flash[:success] = "item saved to your shopping tote!"
      render 'index'
    else
      #flash[:failed] = "item not saved to your shopping tote :("
    end
  end

  def edit
  end

  def destroy
  end

  private
    def tote_item_params
      params.require(:tote_item).permit(:quantity, :price, :status, :posting_id, :user_id)
    end

end
