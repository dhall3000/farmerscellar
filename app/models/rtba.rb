class Rtba < ActiveRecord::Base
  belongs_to :user
  has_many :rtauthorizations
end
