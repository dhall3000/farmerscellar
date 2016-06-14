class RemoveUnitCategoryFromPostings < ActiveRecord::Migration
  def change
    remove_column :postings, :unit_category_id
  end
end
