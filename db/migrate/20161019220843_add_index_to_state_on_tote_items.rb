class AddIndexToStateOnToteItems < ActiveRecord::Migration[5.0]
  def change
    add_index :tote_items, :state
  end
end