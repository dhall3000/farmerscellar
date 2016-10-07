module ToteItemsHelper

  def num_order_objects(user)
    tote_items = authorized_items_for(user)
    subscriptions = get_active_subscriptions_by_authorization_state(user)[:authorized]
    return total_num_objects(tote_items, subscriptions)
  end

  def num_tote_objects(user)
    tote_items = unauthorized_items_for(user)
    subscriptions = get_active_subscriptions_by_authorization_state(user)[:unauthorized]
    return total_num_objects(tote_items, subscriptions)
  end

  def total_num_objects(tote_items, subscriptions)

    num_objects = 0

    if !tote_items.nil?
      num_objects = tote_items.count
    end

    if !subscriptions.nil?
      num_objects += subscriptions.count
    end

    return num_objects

  end

  def orders_exist?(user)
    return num_order_objects(user) > 0
  end

  def tote_has_stuff?(user)
    return num_tote_objects(user) > 0
  end

  #gets all tote items for the given user that are ADDED with delivery date of today or in the future (i.e. none from the past)
  def authorized_items_for(user)

    if user.nil? || !user.valid?
      return nil
    end

    #commenting out this one for posterity's sake. if you leave the trailing .where only-today-or-future-deliveries, what happens if the producer
    #is late delivering...needs to slide by a day or two? i hate this scenario and generally it's not going to work i don't think. or is that so?
    #what if you have a producer on monthly deliveries but we make a route by his place weekly. he might call up and say "is there any way you could
    #pick up next week?" also, holidays. what about when normal delivery date is on Christmas day? probably better just leave it with no date for now
    #until we figure out a slicker way of doing delivery slides which i guess we probably just shouldn't do but still unsure how to do holidays
    #and we definitely want delivery cancel feature
    #return ToteItem.joins(:posting).where(user: user, state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]]).where("postings.delivery_date >= ?", Time.zone.now.midnight)
    return ToteItem.where(user: user, state: [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]])

  end

  #gets all tote items for the given user that are ADDED with delivery date of today or in the future (i.e. none from the past)
  def unauthorized_items_for(user)

    if user.nil? || !user.valid?
      return nil
    end

    #commenting out this one for posterity's sake. if you leave the trailing .where only-today-or-future-deliveries, what happens if the producer
    #is late delivering...needs to slide by a day or two? i hate this scenario and generally it's not going to work i don't think. or is that so?
    #what if you have a producer on monthly deliveries but we make a route by his place weekly. he might call up and say "is there any way you could
    #pick up next week?" also, holidays. what about when normal delivery date is on Christmas day? probably better just leave it with no date for now
    #until we figure out a slicker way of doing delivery slides which i guess we probably just shouldn't do but still unsure how to do holidays
    #and we definitely want delivery cancel feature
    #return ToteItem.joins(:posting).where(user: user, state: ToteItem.states[:ADDED]).where("postings.delivery_date >= ?", Time.zone.now.midnight)
    return ToteItem.where(user: user, state: ToteItem.states[:ADDED])

  end

  def get_active_subscriptions_by_authorization_state(user)

    if user.nil? || !user.valid?
      return {}
    end

    active_subscriptions = get_active_subscriptions_for(user)

    if active_subscriptions.nil?
      return {}
    end

    authorized_subscriptions = []
    unauthorized_subscriptions = []    

    active_subscriptions.each do |subscription|
      if subscription.authorized?
        authorized_subscriptions << subscription
      else
        unauthorized_subscriptions << subscription
      end
    end

    return {authorized: authorized_subscriptions, unauthorized: unauthorized_subscriptions}

  end
  
  def all_items_fully_filled?(tote_items)

    if tote_items.nil? || !tote_items.any?
      return true
    end

    tote_items.each do |tote_item|
      if tote_item.zero_filled? || tote_item.partially_filled?
        return false
      end
    end

    return true

  end

  def current_user_current_unauthorized_tote_items
    all_tote_items = current_user_current_tote_items
    if all_tote_items == nil or all_tote_items.count < 1
      return nil
    end
    unauthorized_tote_items = all_tote_items.where(state: ToteItem.states[:ADDED])
    return unauthorized_tote_items
  end

  def current_user_current_unauthorized_subscriptions
    
    active_subscriptions = get_active_subscriptions_for(current_user)

    unauthorized_subscriptions = []

    active_subscriptions.each do |active_subscription|
      if !active_subscription.authorized?
        unauthorized_subscriptions << active_subscription
      end
    end

    return unauthorized_subscriptions

  end

  def url_with_protocol(url)
    /^http/i.match(url) ? url : "http://#{url}"
  end  

  def current_tote_items_for_user(user)

    #2016-04-06 NEW DESCRIPTION!:
    #Ok, enough confuddling things. From now on (until this hack gets yanked/redid) this method is ONLY for fetching tote items that are progressing along the
    #path of getting FILLED, but not FILLED itself. That is, FILLED is not on the "progression" path to getting filled. It is FILLED> So it doesn't count. Neither
    #does NOTFILLED or REMOVED

    #DESCRIPTION: the intent of this method is to get a collection of toteitems that are currently in the abstract, virtual 'tote'. so, old/expired
    #toteitems are not included, nor are those in states REMOVED, FILLED, NOTFILLED etc.
    #actually, that is false. as of this writing, the possible toteitem states are:
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASED: 7}
    #should we display them all except REMOVED? no. we should display all things that are on track to becoming purchased, strictly.
    #in other words, we should display in the tote all the following items:
    #ADDED, AUTHORIZED, COMMITTED and FILLED

    #here's all the toteitems associated with this user
    all = ToteItem.joins(posting: [:user, :product]).where(user_id: user.id)

    #the 'displayable' items are just the ones in the proper states for user viewing
    if all != nil && all.count > 0
      displayable = all.where("tote_items.state = ? or tote_items.state = ? or tote_items.state = ?", ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED])
    end

    if displayable != nil && displayable.count > 0      
      #now, we don't want the user to see old posts. we only want them to see 'current' posts. current posts are those yet to be delivered.
      #however there is one exception to this rule and that is when an item has progressed to the FILLED state but then does not make
      #it to the PURCHASED state, for whatever reason. in this case, the customer owes money but has not yet purchased so we want it to
      #remain in their tote forever until it's purchased
      #current = displayable.where("postings.delivery_date >= ? or state = ? or state = ?", Time.zone.today, ToteItem.states[:FILLED])

      #the above was a good thought. however, we changed the funds collecting model. when the above was in place our funds-collecting model was to pull from customer
      #credit cards every night. we had to change that to reduce transaction fees though. we changed to where we only pull funds after all a customer's products
      #have been delivered for the week. so, theoretically a customer could have a product delivered on a monday and a saturday and for all those days it would
      #the monday product in the tote. this is not good. so we're changing the whole model to where only items currently in motion toward FILLED get displayed.
      #once products are filled/delivered they should drop out of the tote.
      current = displayable.where("postings.delivery_date >= ?", Time.zone.today)
    end

    return current

  end

	def current_user_current_tote_items
    tote_items = current_tote_items_for_user(current_user)
    return tote_items
	end

  def get_active_subscriptions_for(user)

    if user.nil?
      return nil
    end

    return Subscription.where(user: user, on: true)
    
  end

	def tote_has_items(tote_items)
	  tote_items != nil && tote_items.any?
	end

	def get_gross_tote(tote_items, filled = false)
	  total = 0
	  if tote_has_items(tote_items)
	    tote_items.each do |tote_item|
	      total = (total + get_gross_item(tote_item, filled)).round(2)
	    end	  	  		  	  	
	  end
	  total
	end

  def get_gross_item(tote_item, filled = false)
    
    if tote_item == nil
      return 0
    end

    if filled
      return get_gross_cost(tote_item.quantity_filled, tote_item.price)
    else
      return get_gross_cost(tote_item.quantity, tote_item.price)
    end    

  end

  def get_gross_cost(quantity, price)
    return (quantity * price).round(2)
  end

  def get_commission_tote(tote_items, filled = false)

    if !tote_has_items(tote_items)
      return 0
    end

    total_commission = 0

    tote_items.each do |tote_item|
      total_commission = (total_commission + get_commission_item(tote_item, filled)).round(2)
    end    

    return total_commission

  end

  def get_commission_item(tote_item, filled = false)

    if filled
      quantity = tote_item.quantity_filled
    else
      quantity = tote_item.quantity
    end

    commission_factor = tote_item.posting.get_commission_factor
    commission_unit = (tote_item.price * commission_factor).round(2)
    commission_item = (commission_unit * quantity).round(2)

    return commission_item

  end

  def get_payment_processor_fee_tote(tote_items, filled = false)

    if tote_items == nil || tote_items.count == 0
      return 0
    end

    payment_processor_fee_tote = 0

    tote_items.each do |tote_item|
      payment_processor_fee_tote = (payment_processor_fee_tote + get_payment_processor_fee_item(tote_item, filled)).round(2)
    end

    return payment_processor_fee_tote

  end

  def get_payment_processor_fee_item(tote_item, filled = false)

    if tote_item == nil
      return 0
    end

    if filled
      quantity = tote_item.quantity_filled
    else
      quantity = tote_item.quantity
    end

    unit_fee = get_payment_processor_fee_unit(tote_item.price)    
    item_fee = (unit_fee * quantity).round(2)
    
    return item_fee

  end

  def get_payment_processor_fee_unit(unit_price)
    unit_fee = (0.035 * unit_price).round(2)
    return unit_fee
  end

  def get_producer_net_tote(tote_items, filled = false)

    producer_net_tote = 0

    if tote_items == nil || tote_items.count < 1
      return producer_net_tote
    end

    tote_items.each do |tote_item|
      sub_total = get_producer_net_item(tote_item, filled)
      producer_net_tote = (producer_net_tote + sub_total).round(2)
    end

    return producer_net_tote

  end

  def get_producer_net_item(tote_item, filled = false)

    producer_net_item = (get_gross_item(tote_item, filled) - get_payment_processor_fee_item(tote_item, filled) - get_commission_item(tote_item, filled)).round(2)
    
    return producer_net_item

  end

  def make_commission_factor(retail, producer_net)

    commission = retail - producer_net - get_payment_processor_fee_unit(retail)
    commission_factor = commission / retail

    return commission_factor

  end

  def get_commission_factor_tote(tote_items, filled = false)
    
    value = get_gross_tote(tote_items, filled)
    commission = get_commission_tote(tote_items, filled)

    commission_factor = commission / value

    return commission_factor

  end

end
