class BulkBuysController < ApplicationController
  def new
  	@filled_tote_items = ToteItem.where(status: ToteItem.states[:FILLED])  	
  end

  def create

    #create a bulkbuy object
    bulk_buy = BulkBuy.new
    bulk_buy.admins << current_user
    bulk_buy.amount = 0;

    authorizations = {}

  	filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	for filled_tote_item in filled_tote_items
      bulk_buy.tote_items << filled_tote_item
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

#for each authorization...
    authorizations.each do |token, value|
      ftis = value[:filled_tote_items]
      if ftis == nil || !ftis.any?
        next
      end

      bulk_buy.purchase_receivables.build(amount: value[:amount], amount_paid: 0)
      pr = bulk_buy.purchase_receivables.last
      user = User.find(ftis.first.user_id)                      
      pr.users << user

      ftis.each do |fti|
        pr.tote_items << fti
      end
            
      #do the gateway purchase operation
      response = GATEWAY.capture(value[:amount] * 100, value[:authorization].transaction_id)

      gross_amount = response.params["gross_amount"].to_f
      fee_amount = response.params["fee_amount"].to_f
      net_amount = gross_amount - fee_amount

      #create a new purchase object
      pr.purchases.build(
        response: response,
        amount: value[:amount],
        token: token,
        payer_id: value[:authorization].payer_id,
        gross_amount: gross_amount,
        fee_amount: fee_amount,
        net_amount: net_amount
        )

      purchase = pr.purchases.last
      #associate the purchase object with the authorization
      purchase.authorizations << value[:authorization]

      if response.success?
        #change toteitems' states to PURCHASED
        value[:filled_tote_items].each do |tote_item|
          tote_item.update(status: ToteItem.states[:PURCHASED])
        end
        #associate the purchase object with the bulk buy object
        #TODO: need to update the purchase_receivable.amount_paid attribute
        bulk_buy.amount += purchase.amount
      else    
        #TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed
        #and that their account is now on hold
      end     
      #bulk_buy.purchases << purchase      
    end

  	#save the bulkbuy object
  	bulk_buy.save

  end
end
