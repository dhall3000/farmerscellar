class BulkBuysController < ApplicationController
  def new
  	@tote_items = ToteItem.where(status: ToteItem.states[:FILLED])  	
  end

  def create
    authorizations = {}
  	tote_items = ToteItem.find(params[:tote_item_ids])
  	for tote_item in tote_items
  	  if tote_item.checkouts != nil && tote_item.checkouts.any?
  	  	if tote_item.checkouts.last.authorizations != nil && tote_item.checkouts.last.authorizations.any?
  	  	  authorization = tote_item.checkouts.last.authorizations.last
  	  	  if authorizations[authorization.token] == nil
  	  	  	authorizations[authorization.token] = {amount: 0, authorization: authorization, tote_items: []}
  	  	  end
  	  	  authorizations[authorization.token][:amount] += tote_item.quantity * tote_item.price
  	  	  authorizations[authorization.token][:tote_items] << tote_item
  	  	end
  	  end
  	end

  	#create a bulkbuy object
  	bulk_buy = BulkBuy.new
  	bulk_buy.admins << current_user

  	#for each authorization
  	authorizations.each do |key, value|  		
  	  #do the gateway purchase operation
  	  response = GATEWAY.purchase(value[:amount] * 100, token: key, payer_id: value[:authorization].payer_id)  	  
  	  if response.success?
  	    #create a new purchase object
  	    purchase = Purchase.new(response: response, amount: value[:amount], token: key, payer_id: value[:authorization].payer_id)
  	    #associate the purchase object with the authorization
  	    purchase.authorizations << value[:authorization]
  	    #change toteitems' states to PURCHASED
  	    value[:tote_items].all.update_all(status: ToteItem.states[:PURCHASED])
   	    #associate the purchase object with the bulk buy object
  	    bulk_buy.purchases << purchase
   	  else  	
  	  	#TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed
   	  end  	  
  	end  	  	  	  	  	

  	#save the bulkbuy object
  	bulk_buy.save

  end
end
