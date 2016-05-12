class AddStateColumnToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :state, :integer, default: 0, null: false
    add_index :postings, :state
  end
end
