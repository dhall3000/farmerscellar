class AddStateColumnToCreditorOrders < ActiveRecord::Migration[5.0]
  def change
    #we want all future rows' nb column to be true by default
    add_column :creditor_orders, :state, :integer, default: 0
    #we want to make all the existing rows' nb column to be false
    CreditorOrder.all.update_all(state: 1)
    change_column :creditor_orders, :state, :integer, null: false
    add_index :creditor_orders, :state
  end
end