class FundsProcessing

	def self.bulk_buy_new

		ret = {}

  	ret[:filled_tote_items] = ToteItem.where(status: ToteItem.states[:FILLED])  	

    user_ids = ret[:filled_tote_items].select(:user_id).distinct    
    ret[:user_infos] = []
    ret[:total_bulk_buy_amount] = 0

    for user_id in user_ids
      user_info = {total_amount: 0, name: ''}
      tote_items_by_user = ret[:filled_tote_items].where(user_id: user_id.user_id)
      for tote_item_by_user in tote_items_by_user
        user_info[:total_amount] = (user_info[:total_amount] + (tote_item_by_user.quantity * tote_item_by_user.price).round(2)).round(2)
        user_info[:name] = tote_item_by_user.user.name
      end
      ret[:total_bulk_buy_amount] = (ret[:total_bulk_buy_amount] + user_info[:total_amount]).round(2)
      ret[:user_infos] << user_info
    end

    return ret

	end

	def self.bulk_buy_create(filled_tote_item_ids, current_user)

    #create a bulkbuy object
    bulk_buy = BulkBuy.new
    bulk_buy.admins << current_user
    bulk_buy.amount = 0

    authorizations = {}

    #get the filled tote items and group them by user's authorization
  	filled_tote_items = ToteItem.where(id: filled_tote_item_ids)
    
    if filled_tote_items == nil || filled_tote_items.count < 1
      return
    end

  	for filled_tote_item in filled_tote_items
      bulk_buy.tote_items << filled_tote_item
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

      bulk_buy.purchase_receivables.build(amount: value[:amount], amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL])
      pr = bulk_buy.purchase_receivables.last
      user = User.find(ftis.first.user_id)                      
      pr.users << user

      ftis.each do |fti|
        pr.tote_items << fti
        fti.update(status: ToteItem.states[:PURCHASEPENDING])
      end                              

      #this represents the total value of everything that was filled for this bulk buy
      bulk_buy.amount = (bulk_buy.amount + value[:amount]).round(2)
    end
  	#save the bulkbuy object
  	bulk_buy.save

  	return {bulk_buy: bulk_buy}

	end

	def self.bulk_purchase_new

		bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	bulk_purchase.load_unpurchased_receivables

  	return {bulk_purchase: bulk_purchase}
  	
	end

	def self.bulk_purchase_create(purchase_receivables)

  	purchase_receivables = PurchaseReceivable.find(purchase_receivables)
  	if purchase_receivables != nil && purchase_receivables.count > 0
  	  bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	  for pr in purchase_receivables
  	    bulk_purchase.purchase_receivables << pr
  	  end
      bulk_purchase.go      
    end

    return {bulk_purchase: bulk_purchase}

	end

end