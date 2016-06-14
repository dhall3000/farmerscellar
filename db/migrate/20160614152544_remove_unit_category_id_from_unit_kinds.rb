class RemoveUnitCategoryIdFromUnitKinds < ActiveRecord::Migration
  def change
    remove_column :unit_kinds, :unit_category_id
  end
end
