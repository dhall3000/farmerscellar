class DeliveriesController < ApplicationController
  def new
    #get postings that have no deliveries and whose delivery date is before tomorrow and that have toteitems in a deliverable state
    
    #-delivery date is before tomorrow
    postings1 = Posting.where("delivery_date < ?", Date.today + 1)
    #-don't have any delivery objects associated
    postings2 = postings1.includes(:delivery_postings).where( delivery_postings: { posting_id: nil } )
    #-have tote_items in any of states FILLED, PURCHASEPENDING, PURCHASED or PURCHASEFAILED
    @delivery_eligible_postings = postings2.includes(:tote_items).where( tote_items: {status: [ToteItem.states[:FILLED], ToteItem.states[:PURCHASEPENDING], ToteItem.states[:PURCHASED], ToteItem.states[:PURCHASEFAILED]]})

debugger
    #get dropsites that must be delivered to for this set of postings

  end

  def create
  end

  def edit
  end

  def update
  end

  def index
  end

  def show
  end

  def destroy
  end
end