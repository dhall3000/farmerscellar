class AddPostingRecurrenceIdToPostings < ActiveRecord::Migration
  def change
    add_reference :postings, :posting_recurrence, index: true
    add_foreign_key :postings, :posting_recurrences
  end
end
