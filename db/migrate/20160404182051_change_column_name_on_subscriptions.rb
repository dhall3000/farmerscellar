class ChangeColumnNameOnSubscriptions < ActiveRecord::Migration
  def change
  	rename_column :subscriptions, :interval, :frequency
  end
end
