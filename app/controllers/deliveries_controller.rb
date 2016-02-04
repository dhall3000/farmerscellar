class DeliveriesController < ApplicationController
  def new
    #get postings that have no deliveries and whose delivery date is before tomorrow and that have toteitems in a deliverable state
    
    #-delivery date is before tomorrow
    postings1 = Posting.where("delivery_date < ?", Date.today + 1)
    #-don't have any delivery objects associated
    postings2 = postings1.includes(:delivery_postings).where( delivery_postings: { posting_id: nil } )
    #-have tote_items in any of states FILLED, PURCHASEPENDING, PURCHASED or PURCHASEFAILED
    @delivery_eligible_postings = postings2.includes(:tote_items).where( tote_items: {status: [ToteItem.states[:FILLED], ToteItem.states[:PURCHASEPENDING], ToteItem.states[:PURCHASED], ToteItem.states[:PURCHASEFAILED]]})    

    #get dropsites that must be delivered to for this set of postings
    user_ids = []

    @delivery_eligible_postings.each do |posting|
      posting.tote_items.each do |ti|
        user_ids << ti.user.id
      end
    end

    users = User.find(user_ids.uniq)
    dropsite_ids = []

    users.each do |user|
      dropsite_ids = user.dropsites.last.id
    end

    @dropsites = Array(Dropsite.find(dropsite_ids))

  end

  def create
    
    delivery = Delivery.create
    postings = Posting.find(delivery_params)

    postings.each do |posting|
      delivery.postings << posting
    end

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

  private
    def delivery_params
      params.require(:posting_ids)
    end

end