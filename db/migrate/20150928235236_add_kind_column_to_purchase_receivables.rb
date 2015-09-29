class AddKindColumnToPurchaseReceivables < ActiveRecord::Migration
  def change
    add_column :purchase_receivables, :kind, :integer
    add_index :purchase_receivables, :kind
  end
end
