class AddLateAddsAllowedColumnToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :late_adds_allowed, :boolean, default: false
  end
end
