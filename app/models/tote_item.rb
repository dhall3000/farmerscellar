class ToteItem < ApplicationRecord
  include ToteItemsHelper

  after_save :set_users_header_dirty_bit

  #this just allows you to hand a subscription and tote item state and it will return the set of tote items in the subscription series that match the given state
  scope :subscription_items_by_state, -> (subscription, state) { joins(posting: {posting_recurrence: :subscriptions}).where(subscription: subscription).where("tote_items.state = ?", state) }
  #when a customer has a subscription where Time.zone.now is between order cutoff and delivery their subscription object will have at least two tote items in its series, one of
  #which will be AUTHORIZED and one of which will be COMMITTED. the auth'd one will be for the next delivery cycle out. but we don't want to show this next-out item to the customer.
  #it clutters up their view (best case) and in the scenaro of a RTF order (Roll Till Filled) it's extra bad because the customer will see two items (one for the upcoming delivery
  #and the other for the one after that) and think FC is playing tricks by signing them up for multiple deliveries, not knowing the system will auto-cancel if the upcoming delivery
  #doesn't get filled. best bet is to just hide the future-most item from customer's view...what they don't know won't hurt them. so this method intends to help with that.
  #logic: if a subscription's tote items series has a COMMITTED item, we only want to return that. if it does not have any COMMITTED items then we want to show them any AUTH'd items
  scope :customer_visible_subscription_items, -> (subscription) { (committed = subscription_items_by_state(subscription, ToteItem.states[:COMMITTED])).any? ? committed : subscription_items_by_state(subscription, ToteItem.states[:AUTHORIZED]) }

  has_many :tote_item_rtauthorizations
  has_many :rtauthorizations, through: :tote_item_rtauthorizations

  has_many :tote_item_checkouts
  has_many :checkouts, through: :tote_item_checkouts

  has_many :bulk_buy_tote_items
  has_many :bulk_buys, through: :bulk_buy_tote_items

  has_many :purchase_receivable_tote_items
  has_many :purchase_receivables, through: :purchase_receivable_tote_items

  has_many :payment_payable_tote_items
  has_many :payment_payables, through: :payment_payable_tote_items

  belongs_to :posting
  belongs_to :user
  belongs_to :subscription

  validates :price, :state, :quantity, presence: true
  validates_presence_of :user, :posting  

  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }  

  def self.states
  	{ADDED: 9, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6}
  end

  def self.get_header_data(user)

    tote = ToteItemsController.helpers.unauthorized_items_for(user)
    tote = tote.nil? ? 0 : tote.count

    calendar = ToteItem.calendar_items_displayable(user)
    calendar = calendar.nil? ? 0 : calendar.count

    subscriptions = ToteItemsController.helpers.num_authorized_subscriptions_for(user)

    ready_for_pickup = user.tote_items_to_pickup
    ready_for_pickup = ready_for_pickup.nil? ? 0 : ready_for_pickup.count

    header_data = {
      tote: tote,
      calendar: calendar,
      subscriptions: subscriptions,
      ready_for_pickup: ready_for_pickup
    }

    return header_data

  end

  def self.valid_state_values?(state_values)

    if state_values.nil?
      return false
    end

    if !state_values.kind_of?(Array)
      return false
    end

    return (state_values - states.values).empty?

  end

  def self.calendar_items_displayable(user)

    if user.dropsite.nil?
      return nil
    end
    
    authorized_subscription_objects = ToteItemsController.helpers.get_authorized_subscription_objects_for(user)

    subscription_items = ToteItem.none
    if !authorized_subscription_objects.nil?
      authorized_subscription_objects.each do |subscription_object|
        subscription_items = subscription_items.or(ToteItem.customer_visible_subscription_items(subscription_object))
      end    
    end
    
    individual_items = where(user: user, subscription: nil, state: [states[:AUTHORIZED], states[:COMMITTED]])    

    ids = (subscription_items.pluck(:id) + individual_items.pluck(:id)).uniq
    visible_items = joins(:posting).where(id: ids).order("postings.delivery_date asc")

    return visible_items

  end

  validates :state, inclusion: { in: ToteItem.states.values }
  validates :state, numericality: {only_integer: true}

  def order_deficiency?
    return additional_units_required_to_fill_my_case > 0 || posting.biggest_order_minimum_producer_net_outstanding > 0
  end

  def friendly_description(use_quantity = true)
    quantity_to_use = use_quantity ? quantity : quantity_filled
    return "#{quantity_to_use.to_s} #{posting.user.farm_name} #{posting.product.name} #{posting.unit.name.pluralize(quantity_to_use)}"    
  end

  def short_friendly_description(use_quantity = true)
    quantity_to_use = use_quantity ? quantity : quantity_filled
    return "#{quantity_to_use.to_s} #{posting.product.name} #{posting.unit.name.pluralize(quantity_to_use)}"    
  end

  def creditor
    return creditor_order.creditor
  end

  def creditor_order
    return posting.creditor_order
  end

  def roll_until_filled?
    return subscription && subscription.on && subscription.kind?(:ROLLUNTILFILLED)
  end

  def cancelable?
    return state?(:ADDED) || state?(:AUTHORIZED)
  end

  def additional_units_required_to_fill_my_case
    return posting.additional_units_required_to_fill_items_case(self)
  end

  #this will tell you if the tote item is crossing a case boundary and hence will only partially fill if nothing changes
  #it should get a name change to .spans_case_boundary?
  def will_partially_fill?
    efq = expected_fill_quantity
    return efq > 0 && efq < quantity
  end

  def expected_fill_quantity
    return posting.expected_fill_quantity(self)
  end

  def delivery_date
    
    if posting.nil?
      return nil
    end

    return posting.delivery_date

  end

  def transition(input, params = {})
    
    new_state = state

    case state


    when ToteItem.states[:ADDED]
      case input
      when :customer_authorized
        new_state = ToteItem.states[:AUTHORIZED]
        posting.add_inbound_order_value_producer_net(quantity)
      when :subscription_authorized
        new_state = ToteItem.states[:AUTHORIZED]
        posting.add_inbound_order_value_producer_net(quantity)
      when :customer_removed
        new_state = ToteItem.states[:REMOVED]
      when :system_removed
        new_state = ToteItem.states[:REMOVED]
      end


    when ToteItem.states[:AUTHORIZED]
      case input
      when :billing_agreement_inactive
        new_state = ToteItem.states[:ADDED]
        posting.add_inbound_order_value_producer_net(-quantity)
      when :customer_removed
        new_state = ToteItem.states[:REMOVED]
        posting.add_inbound_order_value_producer_net(-quantity)
      when :system_removed
        new_state = ToteItem.states[:REMOVED]
        posting.add_inbound_order_value_producer_net(-quantity)
      when :order_cutoffed
        new_state = ToteItem.states[:COMMITTED]      
      end


    when ToteItem.states[:COMMITTED]
      case input
      when :tote_item_not_filled
        new_state = ToteItem.states[:NOTFILLED]
      when :tote_item_filled
        new_state = ToteItem.states[:FILLED]
        update(quantity_filled: params[:quantity_filled])

        #TODO: for right now this works cause we only ever do a single funds transfer per tote item. however, if down the road we ever want to
        #make it so that for a $9 item a person could make three $3 payments we'd need to make the "funds flow objects" created below to key
        #off the inbound quantity_filled, not the self.quantity_filled amount. there's some complexity there which i don't want to deal with now.
        #you'd have to go in to the toeitemhelper methods and change the way it keys off of tote_item.quantity_filled because if you had qf of
        #0 and then you added 3, 3 and then 3 to complete, it would now return values of $3, $6 and $9 for a total of $18. not good.

        #also, the implemnentation of create_funds_flow_objects should reject if self.state != FILLED
        
        if quantity_filled > 0
          
          create_funds_flow_objects

          if subscription
            subscription.fill(params[:quantity_filled])
          end

        end
      end


    #as of now there is not transition away from this state. it is a final state.
    #when ToteItem.states[:FILLED]
      #case input      
      #end


    #as of now there is not transition away from this state. it is a final state.
    #when ToteItem.states[:NOTFILLED]
      #case input      
      #end


    #as of now there is not transition away from this state. it is a final state.
    #when ToteItem.states[:REMOVED]            
      #case input
      #end


    end

    if new_state != state
      
      update(state: new_state)

      case new_state
      when ToteItem.states[:AUTHORIZED]
        update(authorized_at: Time.zone.now)        
      when ToteItem.states[:REMOVED]
      end

    end

  end

  def zero_filled?
    return quantity_filled == 0
  end

  def partially_filled?
    return quantity_filled > 0 && quantity_filled < quantity
  end

  def fully_filled?
    return quantity_filled == quantity
  end

  def quantity_not_filled
    return quantity - quantity_filled
  end

  def self.get_users_with_no_deliveries_later_this_week

    span = ToteItemsController.helpers.time_span(Time.zone.today.midnight, ToteItemsController.helpers.end_of_week)
    time_range = Time.zone.today.midnight..(Time.zone.today.midnight + span[0].days)
    #among these users, which also have toteitems in either AUTHORIZED or COMMITTED states?
    delivery_later_this_week_users = User.select(:id).joins(tote_items: :posting).where("tote_items.state" => [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]], 'postings.delivery_date' => time_range).distinct
    users_with_no_deliveries_later_this_week = User.select(:id).where.not(id: delivery_later_this_week_users)

    return users_with_no_deliveries_later_this_week

  end  

  def state?(state_key)
    return state == ToteItem.states[state_key]
  end

  def authorization

    if !checkouts
      return nil
    end

    if !checkouts.any?
      return nil
    end

    #algo explanation:
    #BACKGROUND:
    #we now have two different kinds of checkouts flows; "one-time" and "billing agreement".
    #we had a production bug where user did one time checkout + authorization of a certain tote item (id # 156). later they
    #added a different tote item then clicked on billing agreement checkout button to begin the process of initially
    #setting up a billing agreement. this created a 2nd Checkout object associated with ti 156. however, user did not follow
    #through and create the billing agreement. instead, they went back to the tote and did a second one time checkout + auth.
    #this second auth object created was only associated with the new ti, not the old, since the old ti's state was already
    #marked as AUTHORIZED. anyhow, when purchase time came the machine looked at tote_item(156).checkouts.last.authorizations.last
    #and came up empty handed because there were no .authorizations associated with .checkouts.last since user didn't follow through
    #EXPLANATION:
    #we want to march down a list of the tote item's checkouts reverse of the order in which they were created and pluck the first one
    #we come across that is not a reference transaction checkout that has an authorization associated with it    

    reverse_checkouts = checkouts.order(created_at: :desc)
    auth = nil

    reverse_checkouts.each do |co|
      if !co.is_rt
        if co.authorizations && co.authorizations.any?
          auth = co.authorizations.order("authorizations.id").last
        end
      end
    end

    return auth

  end

  def rtauthorization
    
    rtauth = nil

    if !rtauthorizations.nil? && rtauthorizations.any?
      rtauth = rtauthorizations.order("rtauthorizations.id").last
    end

    return rtauth
    
  end

  private

    def set_users_header_dirty_bit
      #this makes it so that applicationcontroller will pull in fresh data from the db to update the header..specifically, in this case, the 'tote' link in the header
      user.update(header_data_dirty: true)
    end

    def create_funds_flow_objects
      create_purchase_receivable
      create_payment_payable
    end

    def create_purchase_receivable
      
      pr = PurchaseReceivable.new(amount: get_gross_item(self, filled = true), amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL], state: PurchaseReceivable.states[:READY])
      pr.users << user
      pr.tote_items << self
      pr.save
      
      return pr

    end

    def create_payment_payable
      
      net = get_producer_net_tote([self], filled = true)

      if net == 0.0
        return
      end

      payment_payable = PaymentPayable.new(amount: net.round(2), amount_paid: 0, fully_paid: false)      
      payment_payable.tote_items << self
      payment_payable.save
      creditor_order.add_payment_payable(payment_payable)

    end

end
