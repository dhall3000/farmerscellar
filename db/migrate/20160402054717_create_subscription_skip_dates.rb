class CreateSubscriptionSkipDates < ActiveRecord::Migration
  def change
    create_table :subscription_skip_dates do |t|
      t.datetime :skip_date
      t.references :subscription, index: true

      t.timestamps null: false
    end
    add_foreign_key :subscription_skip_dates, :subscriptions
  end
end
