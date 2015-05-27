class RemoveCaptureIdFromToteItems < ActiveRecord::Migration
  def change
  	remove_column :tote_items, :capture_id
  end
end
