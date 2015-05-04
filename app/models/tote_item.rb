class ToteItem < ActiveRecord::Base
  belongs_to :posting
  belongs_to :user

  def self.states
  	{START: 0, PREAUTHORIZED: 1, COMMITTED: 2, FILLED: 3, NOTFILLED: 4}
  end
  
end
