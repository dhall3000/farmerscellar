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

  validates :price, :status, :quantity, presence: true
  validates_presence_of :user, :posting  

  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }

  #PURCHASEFAILED: this state is for when we process a bulk buy and someone's purchase fails. we kick all their toteitems in to this
  #state, empty out their tote and cut off their account so that they can't order anything more until they square up. when in this state
  #user's tote shoudl show all the items they're on the hook for and when they do payment account stuff the funds should go straight through
  #rather than just authorizing for later capture.
  def self.states
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASEPENDING: 7, PURCHASED: 8, PURCHASEFAILED: 9}
  end

  def self.status(id, newstate)

  	ti = ToteItem.find_by(id: id)
  	if ti != nil
  	  if ti.status == states[:FILLPENDING] && newstate == states[:FILLED]
  	  	#this indeed is a legal state transition
  	  	ti.update_attribute(:status, newstate)
  	  end
  	end  	
  end

  def self.dequeue(posting_id)
  	ti = ToteItem.where(status: states[:COMMITTED], posting_id: posting_id).first
  	
    if ti != nil
  	  ti.update_attribute(:status, states[:FILLPENDING])
    end

  	ti

  end

  def authorization
    if checkouts && checkouts.any? && checkouts.last.authorizations && checkouts.last.authorizations.any?
      checkouts.last.authorizations.last
    end
  end

end
