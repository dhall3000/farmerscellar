class Rtba < ActiveRecord::Base
  belongs_to :user
  has_many :rtauthorizations

  validates_presence_of :user
  validates :token, :ba_id, presence: true

end
