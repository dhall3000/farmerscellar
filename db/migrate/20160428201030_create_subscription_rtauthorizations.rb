class CreateSubscriptionRtauthorizations < ActiveRecord::Migration
  def change
    create_table :subscription_rtauthorizations, id: false do |t|
      t.references :rtauthorization, index: true
      t.references :subscription, index: true

      t.timestamps null: false
    end
    add_foreign_key :subscription_rtauthorizations, :rtauthorizations
    add_foreign_key :subscription_rtauthorizations, :subscriptions
  end
end
