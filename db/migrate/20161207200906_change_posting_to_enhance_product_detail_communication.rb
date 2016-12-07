class ChangePostingToEnhanceProductDetailCommunication < ActiveRecord::Migration[5.0]
  def change
    rename_column :postings, :description, :description_body
    rename_column :postings, :product_attributes, :description
    rename_column :postings, :price_equivalency_description, :price_body
    rename_column :postings, :unit_equivalency_description, :unit_body
  end
end