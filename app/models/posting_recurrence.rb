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

  validates :interval, :on, presence: true
  validates :interval, inclusion: [
    PostingRecurrence.intervals[0][1],
    PostingRecurrence.intervals[1][1],
    PostingRecurrence.intervals[2][1],
    PostingRecurrence.intervals[3][1],
    PostingRecurrence.intervals[4][1],
    PostingRecurrence.intervals[5][1]
  ]

end