class ToteItem < ActiveRecord::Base
  has_many :tote_item_captures
  has_many :captures, through: :tote_item_captures
  belongs_to :posting
  belongs_to :user

  def self.states
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASED: 7}
  end

  def self.status(id, newstate)
  	#TODO: change this to be a setter method instead of this hocus pocus
  	ti = ToteItem.find_by(id: id)
  	if ti != nil
  	  if ti.status == states[:FILLPENDING] && newstate == states[:FILLED]
  	  	#this indeed is a legal state transition
  	  	ti.update_attribute(:status, newstate)
  	  end
  	end  	
  end

  def self.dequeue(posting_id)
  	ti = ToteItem.where(status: 2, posting_id: posting_id).first
  	#probably need to change the state of the ti to something like FILLPENDING. but we need this db operation to be atomic.
  	
    if ti != nil
  	  ti.update_attribute(:status, states[:FILLPENDING])
    end

  	ti

  	#TODO: need to scrutinize this. is it possible two sorters pull up the same tote_item at the same time? say, for example,
  	#they both click 'next' at nearly the exact same time and the server gets half way through processing this request and then
  	#thread-switches over to process the other sorter's request. both requests pull/return the same tote_item record?  	

  end
end
