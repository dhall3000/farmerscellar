class AddColumnsToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :payer_id, :string
    add_index :purchases, :payer_id
    add_column :purchases, :token, :string
    add_index :purchases, :token
    add_column :purchases, :response, :text
  end
end
