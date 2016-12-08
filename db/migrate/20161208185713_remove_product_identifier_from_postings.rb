class RemoveProductIdentifierFromPostings < ActiveRecord::Migration[5.0]
  def change
    remove_column :postings, :product_identifier
  end
end