class AddInboundOrderValueProducerNetToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :inbound_order_value_producer_net, :float, default: 0
    Posting.all.update_all(inbound_order_value_producer_net: 0)
    change_column_null(:postings, :inbound_order_value_producer_net, false)
  end
end