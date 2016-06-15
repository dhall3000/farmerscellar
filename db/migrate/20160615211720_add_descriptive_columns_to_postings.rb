class AddDescriptiveColumnsToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :product_attributes, :string
    add_column :postings, :price_equivalency_description, :string
    add_column :postings, :unit_equivalency_description, :string
  end
end
