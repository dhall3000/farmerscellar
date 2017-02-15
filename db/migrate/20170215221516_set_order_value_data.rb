class SetOrderValueData < ActiveRecord::Migration[5.0]
  def change    
    Posting.where(state: [Posting.states[:OPEN], Posting.states[:COMMITMENTZONE]]).each do |posting|
      posting.add_inbound_order_value_producer_net(posting.total_quantity_authorized_or_committed)
    end
  end
end