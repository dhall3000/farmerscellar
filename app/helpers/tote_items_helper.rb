module ToteItemsHelper
	def current_user_current_tote_items

    #DESCRIPTION: the intent of this method is to get a collection of toteitems that are currently in the abstract, virtual 'tote'. so, old/expired
    #toteitems are not included, nor are those in states REMOVED, FILLED, NOTFILLED etc.

    #here's all the toteitems associated with this user
    all = ToteItem.joins(posting: [:user, :product]).where(user_id: current_user.id)

    #the 'displayable' items are just the ones in the proper states for user viewing
    if all != nil && all.count > 0
      displayable = all.where("status = ? or status = ? or status = ?", ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED])
    end

    #now, we don't want the user to see old posts. we only want them to see 'current' posts. current posts are those yet to be delivered.
    if displayable != nil && displayable.count > 0      
      current = displayable.where("postings.delivery_date >= ?", Date.today)
    end

    return current

	end

	def tote_has_items(tote_items)
	  tote_items != nil && tote_items.any?
	end

	def total_cost_of_tote_items(tote_items)
	  total = 0
	  if tote_has_items(tote_items)
	    tote_items.each do |tote_item|
	      total += get_tote_item_value(tote_item)
	    end	  	  		  	  	
	  end
	  total
	end

  def get_tote_item_value(tote_item)
    
    if tote_item == nil
      return 0
    end

    return tote_item.price * tote_item.quantity

  end

  #the intent here is for you to be able to hand a whole collection of tote_items and get the total commission for all items
  def get_commission(tote_items)
    if !tote_has_items(tote_items)
      return 0
    end

    total_value = 0
    total_commission = 0

    tote_items.each do |tote_item|
      tote_item_value = get_tote_item_value(tote_item)
      #tote_item_commission = tote_item_value * tote_item.posting.product.producer_product_commissions.where(user: tote_item.posting.user).last.commission

      producer = tote_item.posting.user
      product = tote_item.posting.product
      commission_factors = ProducerProductCommission.where(user: producer, product: product)

      #TODO: the following line is superfluous, as far as i can tell. however, i get a sqlliteexception without it. strange!
      #i don't think there's anything magical about calling .to_a. when creating this i was able to get things to succeed
      #as intended when i used a variety of reading methods instead of .to_a
      commission_factors.to_a

      commission_factor = commission_factors.last.commission
      tote_item_commission = tote_item_value * commission_factor      
      total_commission += tote_item_commission
    end    

    return total_commission

  end

  #the intent here is for you to be able to hand a whole collection of tote_items and get the total commission for all items
  def get_commission_factor(tote_items)
    
    value = total_cost_of_tote_items(tote_items)
    commission = get_commission(tote_items)

    commission_factor = commission / value

    return commission_factor

  end
end
