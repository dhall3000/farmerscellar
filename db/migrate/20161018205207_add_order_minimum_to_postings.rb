class AddOrderMinimumToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :order_minimum, :float
  end
end
