class ToteItem < ApplicationRecord
  include ToteItemsHelper

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
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6}
  end

  validates :state, inclusion: { in: ToteItem.states.values }
  validates :state, numericality: {only_integer: true}

  def creditor_obligation
    return posting.creditor_obligation
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

  #this will tell you if the tote item is crossing a case boundary and hence will only partially fill of nothing changes
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
      when :subscription_authorized
        new_state = ToteItem.states[:AUTHORIZED]
      when :customer_removed
        new_state = ToteItem.states[:REMOVED]
      when :system_removed
        new_state = ToteItem.states[:REMOVED]
      end


    when ToteItem.states[:AUTHORIZED]
      case input
      when :billing_agreement_inactive
        new_state = ToteItem.states[:ADDED]
      when :customer_removed
        new_state = ToteItem.states[:REMOVED]
      when :system_removed
        new_state = ToteItem.states[:REMOVED]
      when :commitment_zone_started
        new_state = ToteItem.states[:COMMITTED]      
      end


    when ToteItem.states[:COMMITTED]
      case input
      when :tote_item_not_filled
        new_state = ToteItem.states[:NOTFILLED]
      when :tote_item_filled
        new_state = ToteItem.states[:FILLED]
        update(quantity_filled: params[:quantity_filled])
        
        if quantity_filled > 0
          
          create_funds_flow_objects

          if subscription
            subscription.fill(params[:quantity_filled], self)
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

      if new_state == ToteItem.states[:AUTHORIZED]
        update(authorized_at: Time.zone.now)
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

    num_days_till_end_of_week = ENDOFWEEK - Time.zone.today.wday
    time_range = Time.zone.today.midnight..(Time.zone.today.midnight + num_days_till_end_of_week.days)
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

    def create_funds_flow_objects
      pr = create_purchase_receivable
      pr.create_payment_payable(purchase = nil, creditor_obligation)
    end

    def create_purchase_receivable
      
      pr = PurchaseReceivable.new(amount: get_gross_item(self, filled = true), amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL], state: PurchaseReceivable.states[:READY])
      pr.users << user
      pr.tote_items << self
      pr.save
      
      return pr

    end

end
