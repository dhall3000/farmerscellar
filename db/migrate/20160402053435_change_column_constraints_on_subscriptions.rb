class ChangeColumnConstraintsOnSubscriptions < ActiveRecord::Migration
  def change
  	change_column :subscriptions, :interval, :integer, default: 0, null: false
  end
end
