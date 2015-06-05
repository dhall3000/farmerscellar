class BulkBuysController < ApplicationController
  def new
  	@filled_tote_items = ToteItem.where(status: ToteItem.states[:FILLED])  	
  end

  def create

    #create a bulkbuy object
    @bulk_buy = BulkBuy.new
    @bulk_buy.admins << current_user
    @bulk_buy.amount = 0;

    authorizations = {}

    #get the filled tote items and group them by user's authorization
  	filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	for filled_tote_item in filled_tote_items
      @bulk_buy.tote_items << filled_tote_item
  	  if filled_tote_item.checkouts != nil && filled_tote_item.checkouts.any?
  	  	if filled_tote_item.checkouts.last.authorizations != nil && filled_tote_item.checkouts.last.authorizations.any?
  	  	  authorization = filled_tote_item.checkouts.last.authorizations.last
  	  	  if authorizations[authorization.token] == nil
  	  	  	authorizations[authorization.token] = {amount: 0, authorization: authorization, filled_tote_items: []}
  	  	  end
  	  	  authorizations[authorization.token][:amount] += filled_tote_item.quantity * filled_tote_item.price
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

      @bulk_buy.purchase_receivables.build(amount: value[:amount], amount_paid: 0)
      pr = @bulk_buy.purchase_receivables.last
      user = User.find(ftis.first.user_id)                      
      pr.users << user

      ftis.each do |fti|
        pr.tote_items << fti
      end                  
    end
  	#save the bulkbuy object
  	@bulk_buy.save
  end
end