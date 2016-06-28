class RenameSourceProductIdentifierInPostings < ActiveRecord::Migration
  def change
    rename_column :postings, :source_product_identifier, :product_identifier
  end
end
