class AddModifiersToPostingRecurrences < ActiveRecord::Migration
  def up
  	change_column :posting_recurrences, :interval, :integer, null: false
  	change_column :posting_recurrences, :on, :boolean, null: false
  end
end
