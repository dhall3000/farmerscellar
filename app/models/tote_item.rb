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

  #PURCHASEFAILED: this state is for when we process a bulk buy and someone's purchase fails. we kick all their toteitems in to this
  #state, empty out their tote and cut off their account so that they can't order anything more until they square up. when in this state
  #user's tote shoudl show all the items they're on the hook for and when they do payment account stuff the funds should go straight through
  #rather than just authorizing for later capture.
  def self.states
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASEPENDING: 7, PURCHASED: 8, PURCHASEFAILED: 9, DELIVERED: 10, NOTIFIED: 11}
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
      end


    when ToteItem.states[:AUTHORIZED]
      case input
      when :billing_agreement_inactive
        new_state = ToteItem.states[:ADDED]
      when :customer_removed
        new_state = ToteItem.states[:REMOVED]
      when :commitment_zone_started
        new_state = ToteItem.states[:COMMITTED]
      end


    when ToteItem.states[:COMMITTED]
      case input
      when :not_enough_product
        new_state = ToteItem.states[:NOTFILLED]
      when :tote_item_filled
        new_state = ToteItem.states[:FILLED]
        #create new purchaserecievable here
        create_purchase_receivable
      end


    when ToteItem.states[:FILLED]
      case input
      when :delivered
        new_state = ToteItem.states[:DELIVERED]
      end


    when ToteItem.states[:NOTFILLED]
      case input
      when :notified
        new_state = ToteItem.states[:NOTIFIED]
      end


    when ToteItem.states[:REMOVED]
      
      #end state

    when ToteItem.states[:DELIVERED]
      case input
      when :notified
      end


    when ToteItem.states[:NOTIFIED]

      #end state

    end

    if new_state != state
      update(state: new_state)
    end

  end

  def self.dequeue2(posting_id)
  	return ToteItem.where(state: states[:COMMITTED], posting_id: posting_id).first
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
      pr = PurchaseReceivable.new(amount: get_gross_item(self), amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL])
      pr.users << user
      pr.tote_items << self
      pr.save
    end

end
