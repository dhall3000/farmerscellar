class AddNotNullConstraintToPostings < ActiveRecord::Migration
  def up
  	change_column :postings, :user_id, :integer, null: false
  	change_column :postings, :product_id, :integer, null: false
  	change_column :postings, :unit_kind_id, :integer, null: false
  	change_column :postings, :unit_category_id, :integer, null: false
  end
end
