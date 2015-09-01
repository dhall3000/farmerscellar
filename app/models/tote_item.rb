class ToteItem < ActiveRecord::Base
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

  validates :posting, presence: true
  validates :user, presence: true
  validates :quantity, :price, :status, presence: true

  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 8 }

  def self.states
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASEPENDING: 7, PURCHASED: 8}
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
