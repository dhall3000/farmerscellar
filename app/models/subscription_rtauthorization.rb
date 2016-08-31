class SubscriptionRtauthorization < ApplicationRecord
  belongs_to :rtauthorization
  belongs_to :subscription
end
