module ToteItemsHelper

  def current_user_current_unauthorized_tote_items
    all_tote_items = current_user_current_tote_items
    if all_tote_items == nil or all_tote_items.count < 1
      return nil
    end
    unauthorized_tote_items = all_tote_items.where(status: ToteItem.states[:ADDED])
    return unauthorized_tote_items
  end

  def current_tote_items_for_user(user)

    #DESCRIPTION: the intent of this method is to get a collection of toteitems that are currently in the abstract, virtual 'tote'. so, old/expired
    #toteitems are not included, nor are those in states REMOVED, FILLED, NOTFILLED etc.
    #actually, that is false. as of this writing, the possible toteitem states are:
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASED: 7}
    #should we display them all except REMOVED? no. we should display all things that are on track to becoming purchased, strictly.
    #in other words, we should display in the tote all the following items:
    #ADDED, AUTHORIZED, COMMITTED, FILLPENDING and FILLED
    #a new toteitem state was added....PURCHASEPENDING. this should be displayed to the user as well.

    #here's all the toteitems associated with this user
    all = ToteItem.joins(posting: [:user, :product]).where(user_id: user.id)

    #the 'displayable' items are just the ones in the proper states for user viewing
    if all != nil && all.count > 0
      displayable = all.where("status = ? or status = ? or status = ? or status = ? or status = ? or status = ?", ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED], ToteItem.states[:FILLPENDING], ToteItem.states[:FILLED], ToteItem.states[:PURCHASEPENDING])
    end

    #now, we don't want the user to see old posts. we only want them to see 'current' posts. current posts are those yet to be delivered.
    #however there is one exception to this rule and that is when an item has progressed to the FILLED state but then does not make
    #it to the PURCHASED state, for whatever reason. in this case, the customer owes money but has not yet purchased so we want it to
    #remain in their tote forever until it's purchased
    if displayable != nil && displayable.count > 0      
      current = displayable.where("postings.delivery_date >= ? or status = ? or status = ?", Time.zone.today, ToteItem.states[:FILLED], ToteItem.states[:PURCHASEPENDING])
    end

    return current

  end

	def current_user_current_tote_items
    tote_items = current_tote_items_for_user(current_user)
    return tote_items
	end

	def tote_has_items(tote_items)
	  tote_items != nil && tote_items.any?
	end

	def get_gross_tote(tote_items)
	  total = 0
	  if tote_has_items(tote_items)
	    tote_items.each do |tote_item|
	      total = (total + get_gross_item(tote_item)).round(2)
	    end	  	  		  	  	
	  end
	  total
	end

  def get_gross_item(tote_item)
    
    if tote_item == nil
      return 0
    end

    return (tote_item.price * tote_item.quantity).round(2)

  end

  def get_commission_tote(tote_items)

    if !tote_has_items(tote_items)
      return 0
    end

    total_commission = 0

    tote_items.each do |tote_item|
      total_commission = (total_commission + get_commission_item(tote_item)).round(2)
    end    

    return total_commission

  end

  def get_commission_item(tote_item)

    commission_factor = get_commission_factor(tote_item.posting.user, tote_item.posting.product)
    commission_unit = (tote_item.price * commission_factor).round(2)
    commission_item = (commission_unit * tote_item.quantity).round(2)

    return commission_item

  end

  #the intent here is for you to be able to hand a whole collection of tote_items and get the total commission for all items
  def get_commission_factor_tote(tote_items)
    
    value = get_gross_tote(tote_items)
    commission = get_commission_tote(tote_items)

    commission_factor = commission / value

    return commission_factor

  end

  def get_payment_processor_fee_tote(tote_items)

    if tote_items == nil || tote_items.count == 0
      return 0
    end

    payment_processor_fee_tote = 0

    tote_items.each do |tote_item|
      payment_processor_fee_tote = (payment_processor_fee_tote + get_payment_processor_fee_item(tote_item)).round(2)
    end

    return payment_processor_fee_tote

  end

  def get_payment_processor_fee_item(tote_item)

    if tote_item == nil
      return 0
    end

    unit_fee = (0.035 * tote_item.price).round(2)
    item_fee = (unit_fee * tote_item.quantity).round(2)
    
    return item_fee

  end

  def get_producer_net_tote(tote_items)

    producer_net_tote = 0

    if tote_items == nil || tote_items.count < 1
      return producer_net_tote
    end

    tote_items.each do |tote_item|
      producer_net_tote = (producer_net_tote + get_producer_net_item(tote_item)).round(2)
    end

    return producer_net_tote

  end

  def get_producer_net_item(tote_item)
    producer_net_item = (get_gross_item(tote_item) - get_payment_processor_fee_item(tote_item) - get_commission_item(tote_item)).round(2)
    return producer_net_item
  end

  def get_commission_factor(producer, product)

    commission_factors = ProducerProductCommission.where(user: producer, product: product)

    #TODO: the following line is superfluous, as far as i can tell. however, i get a sqlliteexception without it. strange!
    #i don't think there's anything magical about calling .to_a. when creating this i was able to get things to succeed
    #as intended when i used a variety of reading methods instead of .to_a
    commission_factors.to_a

    return commission_factors.order(:created_at).last.commission

  end

end
