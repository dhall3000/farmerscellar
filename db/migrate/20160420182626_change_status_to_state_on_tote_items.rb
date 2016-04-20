class ChangeStatusToStateOnToteItems < ActiveRecord::Migration
  def change
    rename_column :tote_items, :status, :state
  end
end