class ChangeSeveralColumnsOnPostings < ActiveRecord::Migration[5.0]
  def change
    change_column :postings, :description_body, :text
    change_column_null :postings, :description_body, true
    change_column_null :postings, :price, false
    change_column_null :postings, :live, false
    add_index :postings, :live
    add_index :postings, :delivery_date
    change_column_null :postings, :description, false
    change_column_default :postings, :units_per_case, from: 1, to: nil
    change_column_default :postings, :order_minimum_producer_net, from: 0.0, to: nil
  end
end