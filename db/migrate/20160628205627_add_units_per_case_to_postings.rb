class AddUnitsPerCaseToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :units_per_case, :integer, default: 1
  end
end
