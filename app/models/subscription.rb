class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :posting_recurrence
  belongs_to :rtauthorization
  has_many :subscription_skip_dates
  has_many :tote_items

  validates :interval, :quantity, presence: true
  validates :interval, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates_presence_of :posting_recurrence, :user
end
