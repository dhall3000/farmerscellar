class AddProductIdCodeToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :product_id_code, :string
  end
end
