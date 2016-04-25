class AddStateColumnToPurchaseReceivables < ActiveRecord::Migration
  def change
    add_column :purchase_receivables, :state, :integer, default: 0
    add_index :purchase_receivables, :state
  end
end
