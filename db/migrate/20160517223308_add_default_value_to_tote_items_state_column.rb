class AddDefaultValueToToteItemsStateColumn < ActiveRecord::Migration
  def change
    change_column_default :tote_items, :state, 0
  end
end
