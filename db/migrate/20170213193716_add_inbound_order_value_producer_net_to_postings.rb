class AddInboundOrderValueProducerNetToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :inbound_order_value_producer_net, :float, default: 0, null: false
  end
end