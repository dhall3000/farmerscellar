class AddRtauthorizationReferenceToToteItems < ActiveRecord::Migration
  def change
    add_reference :tote_items, :rtauthorization, index: true
    add_foreign_key :tote_items, :rtauthorizations
  end
end
