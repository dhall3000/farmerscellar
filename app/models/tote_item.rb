class ToteItem < ActiveRecord::Base
  belongs_to :posting
  belongs_to :user

  def self.states
  	{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 3, NOTFILLED: 4, REMOVED: 5, PURCHASED: 6}
  end
  
end
