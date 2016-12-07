class AddImportantNotesColumnsToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :important_notes, :string
    add_column :postings, :important_notes_body, :string
  end
end