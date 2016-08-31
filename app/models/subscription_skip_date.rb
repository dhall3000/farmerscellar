class SubscriptionSkipDate < ApplicationRecord
  belongs_to :subscription

  validates :skip_date, presence: true
  validates_presence_of :subscription
end
