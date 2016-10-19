class AddOrderMinimumToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :order_minimum, :float, default: 0
  end
end
