module ToteItemsHelper
	def current_user_current_tote_items
		#TODO: this should return only the tote items that are in the cart and 'current'. what I mean is we don't want 'removed' items and we don't want items from postings past
		ToteItem.includes(posting: [:user, :product]).where(user_id: current_user.id)
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
end
