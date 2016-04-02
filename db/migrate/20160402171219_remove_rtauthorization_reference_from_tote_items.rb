class RemoveRtauthorizationReferenceFromToteItems < ActiveRecord::Migration
  def change
    remove_reference :tote_items, :rtauthorization, index: true
    remove_foreign_key :tote_items, :rtauthorizations
  end
end
