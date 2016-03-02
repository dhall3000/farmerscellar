class AddDefaultValuesToPostingRecurrences < ActiveRecord::Migration
  def change
  	change_column_default :posting_recurrences, :interval, 0
  	change_column_default :posting_recurrences, :on, false
  end
end
