class AddOrderValueToCreditorOrder < ActiveRecord::Migration[5.0]
  def change
    
    add_column :creditor_orders, :order_value_producer_net, :float

    CreditorOrder.all.each do |co|
      ovpn = 0.0
      co.postings.each do |posting|
        ovpn = (ovpn + posting.outbound_order_value_producer_net).round(2)
      end
      co.update(order_value_producer_net: ovpn)
    end

    change_column :creditor_orders, :order_value_producer_net, :float, default: 0.0, null: false

  end
end