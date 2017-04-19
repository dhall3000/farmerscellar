class AddLastWhatsNewViewColumnToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_whats_new_view, :datetime
  end
end