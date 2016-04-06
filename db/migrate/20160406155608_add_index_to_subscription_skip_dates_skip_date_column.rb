class AddIndexToSubscriptionSkipDatesSkipDateColumn < ActiveRecord::Migration
  def change
  	add_index :subscription_skip_dates, :skip_date
  end
end
