class AddAuthorizedAtColumnToToteItems < ActiveRecord::Migration
  def change
    add_column :tote_items, :authorized_at, :datetime
    add_index :tote_items, :authorized_at
  end
end
