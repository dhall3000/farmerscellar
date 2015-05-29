class BulkBuysController < ApplicationController
  def new
  	@filled_tote_items = ToteItem.where(status: ToteItem.states[:FILLED])  	
  end

  def create
    authorizations = {}
  	filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	for filled_tote_item in filled_tote_items
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

  	#create a bulkbuy object
  	bulk_buy = BulkBuy.new
  	bulk_buy.admins << current_user
    bulk_buy.amount = 0;

  	#for each authorization
  	authorizations.each do |key, value|  		
  	  #do the gateway purchase operation
  	  response = GATEWAY.capture(value[:amount] * 100, value[:authorization].transaction_id)
  	  if response.success?
  	    #create a new purchase object
  	    purchase = Purchase.new(response: response, amount: value[:amount], token: key, payer_id: value[:authorization].payer_id)  	    
  	    #associate the purchase object with the authorization
  	    purchase.authorizations << value[:authorization]
  	    #change toteitems' states to PURCHASED
  	    value[:filled_tote_items].each do |tote_item|
          tote_item.update(status: ToteItem.states[:PURCHASED])
        end

   	    #associate the purchase object with the bulk buy object
  	    bulk_buy.purchases << purchase
        bulk_buy.amount += purchase.amount
   	  else  	
  	  	#TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed  	  	
   	  end  	  
  	end  	  	  	  	  	

  	#save the bulkbuy object
  	bulk_buy.save

  end
end
