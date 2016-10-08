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

  #gets all tote items for the given user that are either AUTHORIZED or COMMITTED
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

  #gets all tote items for the given user that are ADDED
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

  def all_items_for(user)
    return authorized_items_for(user).or(unauthorized_items_for(user))
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

  def url_with_protocol(url)
    /^http/i.match(url) ? url : "http://#{url}"
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
