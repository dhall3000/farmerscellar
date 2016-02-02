class BulkBuysController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new
  	@filled_tote_items = ToteItem.where(status: ToteItem.states[:FILLED])  	

    user_ids = @filled_tote_items.select(:user_id).distinct    
    @user_infos = []
    @total_bulk_buy_amount = 0

    for user_id in user_ids
      user_info = {total_amount: 0, name: ''}
      tote_items_by_user = @filled_tote_items.where(user_id: user_id.user_id)
      for tote_item_by_user in tote_items_by_user
        user_info[:total_amount] = (user_info[:total_amount] + (tote_item_by_user.quantity * tote_item_by_user.price).round(2)).round(2)
        user_info[:name] = tote_item_by_user.user.name
      end
      @total_bulk_buy_amount = (@total_bulk_buy_amount + user_info[:total_amount]).round(2)
      @user_infos << user_info
    end
  end

  def create

    #create a bulkbuy object
    @bulk_buy = BulkBuy.new
    @bulk_buy.admins << current_user
    @bulk_buy.amount = 0;

    authorizations = {}

    #get the filled tote items and group them by user's authorization
  	filled_tote_items = ToteItem.where(id: params[:filled_tote_item_ids])
    
    if filled_tote_items == nil || filled_tote_items.count < 1
      return
    end

  	for filled_tote_item in filled_tote_items
      @bulk_buy.tote_items << filled_tote_item
  	  if filled_tote_item.checkouts != nil && filled_tote_item.checkouts.any?
  	  	if filled_tote_item.checkouts.last.authorizations != nil && filled_tote_item.checkouts.last.authorizations.any?
  	  	  authorization = filled_tote_item.checkouts.last.authorizations.last
  	  	  if authorizations[authorization.token] == nil
  	  	  	authorizations[authorization.token] = {amount: 0, authorization: authorization, filled_tote_items: []}
  	  	  end
  	  	  authorizations[authorization.token][:amount] = (authorizations[authorization.token][:amount] + (filled_tote_item.quantity * filled_tote_item.price).round(2)).round(2)
  	  	  authorizations[authorization.token][:filled_tote_items] << filled_tote_item
  	  	end
  	  end
  	end

    #authorizations[token][:amount] //this is the purchase_receivable amount
    #authorizations[token][:authorization]
    #authorizations[token][:filled_tote_items]

    authorizations.each do |token, value|
      ftis = value[:filled_tote_items]
      if ftis == nil || !ftis.any?
        next
      end

      @bulk_buy.purchase_receivables.build(amount: value[:amount], amount_paid: 0, kind: PurchaseReceivable.kind[:NORMAL])
      pr = @bulk_buy.purchase_receivables.last
      user = User.find(ftis.first.user_id)                      
      pr.users << user

      ftis.each do |fti|
        pr.tote_items << fti
        fti.update(status: ToteItem.states[:PURCHASEPENDING])
      end                              

      #this represents the total value of everything that was filled for this bulk buy
      @bulk_buy.amount = (@bulk_buy.amount + value[:amount]).round(2)
    end
  	#save the bulkbuy object
  	@bulk_buy.save
  end
end
