class AddKindColumnToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :kind, :integer
    Subscription.all.update_all(kind: Subscription.kinds[:NORMAL])
    change_column :subscriptions, :kind, :integer, default: 0, null: false
  end
end