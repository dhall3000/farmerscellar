class AddDateToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :delivery_date, :date
  end
end
