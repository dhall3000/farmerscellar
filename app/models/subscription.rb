class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :posting_recurrence
  has_many :subscription_skip_dates

  validates :interval, presence: true
  validates :interval, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates_presence_of :posting_recurrence, :user
end
