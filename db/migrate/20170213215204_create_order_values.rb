class CreateOrderValues < ActiveRecord::Migration[5.0]
  def change
    create_table :order_values do |t|
      t.float :inbound_producer_net, default: 0, null: false
      t.datetime :order_cutoff, null: false
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :order_values, :order_cutoff
  end
end