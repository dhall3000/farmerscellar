class ChangeIntervalColumnNameOnPostingRecurrence < ActiveRecord::Migration
  def change
  	rename_column :posting_recurrences, :interval, :frequency
  end
end
