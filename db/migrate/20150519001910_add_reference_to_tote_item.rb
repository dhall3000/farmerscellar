class AddReferenceToToteItem < ActiveRecord::Migration
  def change
    add_reference :tote_items, :capture, index: true
    add_foreign_key :tote_items, :captures
  end
end
