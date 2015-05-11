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
	      total += tote_item.price * tote_item.quantity
	    end	  	  		  	  	
	  end
	  total
	end
end
