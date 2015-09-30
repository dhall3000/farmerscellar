class AddNotesColumnToUserAccountStates < ActiveRecord::Migration
  def change
    add_column :user_account_states, :notes, :text
  end
end
