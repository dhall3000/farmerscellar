class ToteItem < ActiveRecord::Base
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

  def set_initial_state
    self.state = ToteItem.states[:ADDED]
  end

  def transition(input)
    
    new_state = state

    case state


    when ToteItem.states[:ADDED]
      case input
      when :customer_authorized || :subscription_authorized
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
        #create new purchaserecievable here
        create_purchase_receivable
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
    end

  end

  def self.get_users_with_no_deliveries_later_this_week

    num_days_till_end_of_week = ENDOFWEEK - Time.zone.today.wday
    time_range = Time.zone.today.midnight..(Time.zone.today.midnight + num_days_till_end_of_week.days)
    #among these users, which also have toteitems in either AUTHORIZED or COMMITTED states?
    delivery_later_this_week_users = User.select(:id).joins(tote_items: :posting).where("tote_items.state" => [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]], 'postings.delivery_date' => time_range).distinct
    users_with_no_deliveries_later_this_week = User.select(:id).where.not(id: delivery_later_this_week_users)

    return users_with_no_deliveries_later_this_week

  end  

  def deauthorize
    if state?(:AUTHORIZED)
      update(state: ToteItem.states[:ADDED])
    end    
  end

  def state?(state_key)
    return state == ToteItem.states[state_key]
  end

  def authorization
    if checkouts && checkouts.any? && checkouts.last.authorizations && checkouts.last.authorizations.any?
      checkouts.last.authorizations.last
    end
  end

  private

    def create_purchase_receivable
      pr = PurchaseReceivable.new(amount: get_gross_item(self), amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL], state: PurchaseReceivable.states[:READY])
      pr.users << user
      pr.tote_items << self
      pr.save
    end

end
