class AddSubscriptionReferenceToToteItems < ActiveRecord::Migration
  def change
    add_reference :tote_items, :subscription, index: true
    add_foreign_key :tote_items, :subscriptions
  end
end
