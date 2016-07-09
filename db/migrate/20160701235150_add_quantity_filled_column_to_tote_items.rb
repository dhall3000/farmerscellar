class AddQuantityFilledColumnToToteItems < ActiveRecord::Migration
  def change
    add_column :tote_items, :quantity_filled, :integer, default: 0

    ToteItem.all.each do |tote_item|
      if tote_item.state?(:FILLED)
        tote_item.update(quantity_filled: tote_item.quantity)
      else
        tote_item.update(quantity_filled: 0)
      end
    end

  end
end
