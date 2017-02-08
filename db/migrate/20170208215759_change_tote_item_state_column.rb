class ChangeToteItemStateColumn < ActiveRecord::Migration[5.0]
  def change
    ToteItem.where(state: 0).update(state: 9)
    ToteItem.where(state: nil).update(state: 9)
    change_column_null :tote_items, :state, false, 9
    change_column_default :tote_items, :state, from: 0, to: 9
  end
end