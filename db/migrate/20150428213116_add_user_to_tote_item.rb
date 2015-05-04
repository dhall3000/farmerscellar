class AddUserToToteItem < ActiveRecord::Migration
  def change
    add_reference :tote_items, :user, index: true
    add_foreign_key :tote_items, :users
  end
end
