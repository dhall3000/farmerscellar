class AddSourceProductIdentifierToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :source_product_identifier, :string
  end
end
