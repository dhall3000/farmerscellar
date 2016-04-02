class ChangeColumnConstraintsOnSubscriptionSkipDates < ActiveRecord::Migration
  def change
  	change_column :subscription_skip_dates, :skip_date, :datetime, null: false
  	change_column :subscription_skip_dates, :subscription_id, :integer, null: false
  end
end
