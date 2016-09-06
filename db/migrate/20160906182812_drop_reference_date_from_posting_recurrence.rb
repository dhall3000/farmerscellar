class DropReferenceDateFromPostingRecurrence < ActiveRecord::Migration[5.0]
  def change
  	remove_column :posting_recurrences, :reference_date
  end
end