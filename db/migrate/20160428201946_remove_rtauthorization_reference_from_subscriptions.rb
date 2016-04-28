class RemoveRtauthorizationReferenceFromSubscriptions < ActiveRecord::Migration
  def change
    remove_reference :subscriptions, :rtauthorization, index: true
    remove_foreign_key :subscriptionsbun, :rtauthorizations
  end
end