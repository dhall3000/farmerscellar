class RemoveLateAddsAllowedFromPostings < ActiveRecord::Migration[5.0]
  def change
    remove_column :postings, :late_adds_allowed
  end
end