class PostingRecurrence < ActiveRecord::Base
  has_many :postings

  def self.intervals  	
  	[
  		["No", 0],
  		["Every week", 1],
  		["Every two weeks", 2],
  		["Every three weeks", 3],
  		["Every four weeks", 4],
  		["Monthly", 5]
  	]
  end
end
