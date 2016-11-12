class AddCreditorReferenceToCreditorOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :creditor_orders, :creditor_id, :integer
    add_index :creditor_orders, :creditor_id
    add_foreign_key :creditor_orders, :users, column: :creditor_id
  end
end