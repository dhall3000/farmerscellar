class DeliveriesController < ApplicationController
  def new
  	posting_id = params[:posting_id]  	
    #below is a list of all tote_items associated with this posting id
	  @tote_items = ToteItem.where(posting_id: posting_id)
    @delivery = Delivery.find_by(posting_id: posting_id)
  	if @delivery == nil
	    #@delivery = Delivery.new(posting_id: posting_id)
  	else
  	  render 'edit'
  	end

  end

  def create
    posting_id = params[:posting_id]
    @delivery = Delivery.find_by(posting_id: posting_id)
    if @delivery == nil
    else
    end
  end

  def edit
  end

  def update
  end
end
