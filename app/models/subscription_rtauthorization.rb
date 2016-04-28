class SubscriptionRtauthorization < ActiveRecord::Base
  belongs_to :rtauthorization
  belongs_to :subscription
end
