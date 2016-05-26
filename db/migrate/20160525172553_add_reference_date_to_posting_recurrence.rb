class AddReferenceDateToPostingRecurrence < ActiveRecord::Migration
  
  def up
    add_column :posting_recurrences, :reference_date, :datetime
    change_column_null :posting_recurrences, :reference_date, false, Time.zone.now.midnight + 1000.years
  end

  def down
    remove_column :posting_recurrences, :reference_date, :datetime
  end

end
