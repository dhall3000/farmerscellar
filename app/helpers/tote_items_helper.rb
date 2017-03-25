module ToteItemsHelper

  def pickup_range_for(datetime)

    start_time = start_of_next_week(datetime) - 6.days
    end_time = start_of_next_week(datetime) - 6.days

    while end_time.wday != FOODCLEAROUTDAYTIME[:wday].to_i
      end_time += 1.day
    end

    end_time += FOODCLEAROUTDAYTIME[:hour].to_i.hours

    return [start_time, end_time]

  end

  def food_category_path_helper(food_category)
    if food_category
      postings_path(food_category: food_category.name)
    else
      postings_path
    end
  end

  def time_span(start_date, end_date)

    span = end_date - start_date

    minutes, seconds = span.divmod(60)            #=> e.g. [4515, 21]
    hours, minutes = minutes.divmod(60)           #=> e.g. [75, 15]
    days, hours = hours.divmod(24)

    return [days, hours, minutes, seconds]

  end

  def end_of_week(relative_to = nil)
    return start_of_next_week(relative_to) - 1.day    
  end

  def start_of_next_week(relative_to = nil)

    if relative_to.nil?
      relative_to = Time.zone.now
    end

    if relative_to.wday == STARTOFWEEK
      relative_to += 1.day
    end

    next_week_start = relative_to.midnight    

    while next_week_start.wday != STARTOFWEEK
      next_week_start += 1.day
    end
    
    return next_week_start
    
  end

  def num_order_objects(user)
    tote_items = authorized_items_for(user)
    subscriptions = get_active_subscriptions_by_authorization_state(user, include_paused_subscriptions = false, kind = Subscription.kinds[:NORMAL])[:authorized]
    return total_num_objects(tote_items, subscriptions)
  end

  def num_tote_objects(user)
    tote_items = unauthorized_items_for(user)
    subscriptions = get_active_subscriptions_by_authorization_state(user, include_paused_subscriptions = true, kind = Subscription.kinds[:NORMAL])[:unauthorized]
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

  def get_active_subscriptions_by_authorization_state(user, include_paused_subscriptions = true, kind = nil)

    if user.nil? || !user.valid?
      return {}
    end

    active_subscriptions = get_active_subscriptions_for(user, include_paused_subscriptions, kind)

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

  def num_authorized_subscriptions_for(user)
    authorized_subscriptions = get_authorized_subscriptions_for(user)
    num_authorized_subscriptions = authorized_subscriptions.nil? ? 0 : authorized_subscriptions.count
  end

  def get_authorized_subscriptions_for(user)

    rtba = user.get_active_rtba

    if rtba.nil?
      return nil
    end

    return Subscription.joins(rtauthorizations: :rtba).where(user: user, on: true, paused: false, kind: Subscription.kinds[:NORMAL]).where("rtauthorizations.rtba_id" => rtba.id).distinct

  end

  def get_active_subscriptions_for(user, include_paused_subscriptions = true, kind = nil)

    if user.nil?
      return nil
    end

    if include_paused_subscriptions
      if kind
        return Subscription.where(user: user, on: true, kind: kind)
      else
        return Subscription.where(user: user, on: true)
      end      
    else
      if kind
        return Subscription.where(user: user, on: true, paused: false, kind: kind)
      else
        return Subscription.where(user: user, on: true, paused: false)
      end      
    end    
    
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

  def any_items_filled?(tote_items)
    
    if tote_items.nil? || !tote_items.any?
      return false
    end

    tote_items.each do |tote_item|
      if tote_item.fully_filled? || tote_item.partially_filled?
        return true
      end
    end

    return false
    
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
    
    commission_unit = tote_item.posting.commission_per_unit
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

    commission = (retail - producer_net - get_payment_processor_fee_unit(retail)).round(2)
    commission_factor = commission / retail

    return commission_factor

  end

  def get_producer_net_unit(commission_factor, retail_price)
    
    pp_fee = get_payment_processor_fee_unit(retail_price)
    commission_per_unit = (retail_price * commission_factor).round(2)
    producer_net_unit = (retail_price - commission_per_unit - pp_fee).round(2)

    return producer_net_unit

  end

  def get_retail_price(commission, producer_net)
    return (producer_net / (1.0 - (commission + 0.035))).round(2)
  end

  def get_commission_factor_tote(tote_items, filled = false)
    
    value = get_gross_tote(tote_items, filled)
    commission = get_commission_tote(tote_items, filled)

    commission_factor = commission / value

    return commission_factor

  end

end
