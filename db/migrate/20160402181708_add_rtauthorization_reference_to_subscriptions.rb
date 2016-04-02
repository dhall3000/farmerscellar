class AddRtauthorizationReferenceToSubscriptions < ActiveRecord::Migration
  def change
    add_reference :subscriptions, :rtauthorization, index: true
    add_foreign_key :subscriptions, :rtauthorizations
  end
end
