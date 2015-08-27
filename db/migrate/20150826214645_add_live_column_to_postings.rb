class AddLiveColumnToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :live, :boolean
  end
end
