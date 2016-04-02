class ChangeColumnConstraintsOnSubscriptionTwo < ActiveRecord::Migration
  def change
  	change_column :subscriptions, :price, :float, null: false
  	change_column :subscriptions, :quantity, :integer, null: false
  end
end
