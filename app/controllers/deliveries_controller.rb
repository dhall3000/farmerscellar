class DeliveriesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new

    prod_mode = true

    #get postings that have no deliveries and whose delivery date is before tomorrow and that have toteitems in a deliverable state
    #-delivery date is before tomorrow
    postings1 = Posting.where("delivery_date < ?", Time.zone.now)

    if prod_mode
      #-don't have any delivery objects associated
      postings2 = postings1.includes(:delivery_postings).where( delivery_postings: { posting_id: nil } )
      #-have tote_items in any of states specified states
      @delivery_eligible_postings = postings2.includes(:tote_items).where( tote_items: {status: get_tote_item_states})    
    else
      #the purpose of this is for developing the deliveries features. the prod code creates a new delivery only with postings that have elsewhere been marked as delivered.
      #this here dev code will allow you to just keep using the same postings in the creation of new deliveries so that you don't have to repeatedly reseed the db      
      @delivery_eligible_postings = postings1.includes(:tote_items).where( tote_items: {status: get_tote_item_states})    
    end

    #get dropsites that must be delivered to for this set of postings
    @dropsites = get_dropsites_from_postings(@delivery_eligible_postings)      
  end

  def create
    
    @delivery = Delivery.create
    postings = Posting.find(delivery_params)

    postings.each do |posting|
      @delivery.postings << posting
    end

    flash[:success] = "New delivery created."
    redirect_to delivery_path(@delivery)

  end

  def edit
    @delivery = Delivery.find(params[:id])
    @dropsites_deliverable = get_dropsites_from_postings(@delivery.postings)
  end

  def update
    @delivery = Delivery.find(params[:id])
    @dropsite = Dropsite.find(params[:dropsite_id])
    @delivery.dropsites << @dropsite

    send_delivery_notification(@delivery, @dropsite)

    @dropsites_deliverable = get_dropsites_from_postings(@delivery.postings)
    flash.now[:success] = @dropsite.name + " delivery saved and delivery notifications sent."
    render 'show'
  end

  def index
    @deliveries = Delivery.all.order(created_at: :desc)
  end

  def show
    @delivery = Delivery.find(params[:id])
    @dropsites_deliverable = get_dropsites_from_postings(@delivery.postings)
  end

  def destroy
  end

  private
    
    def delivery_params
      params.require(:posting_ids)
    end

    def send_delivery_notification(delivery, dropsite)
      
      #this relation has ALL users and their most recently specified dropsite
      users = UserDropsite.select("user_id, dropsite_id, max(created_at) as created_at").group(:user_id, :dropsite_id)

      tote_items_by_user_id = {}

      users.each do |user|
        if user.dropsite_id != dropsite.id
          next
        end

        if !tote_items_by_user_id.has_key?(user.user_id)
          tote_items_by_user_id[user.user_id] = {tote_items: []}
        end
        
      end
      
      delivery.postings.each do |posting|
        posting.tote_items.each do |tote_item|          
          if get_tote_item_states.include? tote_item.status
            if tote_items_by_user_id.has_key?(tote_item.user_id)
              tote_items_by_user_id[tote_item.user_id][:tote_items] << tote_item
            end
          end
        end
      end

      tote_items_by_user_id.each do |user_id, value|
        tote_items = nil
        if value != nil
          tote_items = value[:tote_items]
        end

        if tote_items.nil? || !tote_items.any?
          next
        end

        if user_id.nil?
          next
        end

        user = User.find(user_id)
        
        if user.pickup_code.nil?
          set_pickup_code_if_nil(dropsite)          
        end

        UserMailer.delivery_notification(user, dropsite, tote_items).deliver_now
        
      end

    end

    def get_tote_item_states
      return [ToteItem.states[:FILLED], ToteItem.states[:NOTFILLED], ToteItem.states[:PURCHASEPENDING], ToteItem.states[:PURCHASED], ToteItem.states[:PURCHASEFAILED]]
    end

    #returns an array of dropsites from the given postings
    def get_dropsites_from_postings(postings)

      user_ids = []

      postings.each do |posting|        
        posting.tote_items.where(status: get_tote_item_states).each do |ti|
          user_ids << ti.user.id
        end
      end

      users = User.find(user_ids.uniq)
      dropsite_ids = []

      users.each do |user|
        dropsite_ids << user.user_dropsites.order(:created_at).last.dropsite.id
      end

      dropsites = Array(Dropsite.find(dropsite_ids.uniq))

      return dropsites

    end

end