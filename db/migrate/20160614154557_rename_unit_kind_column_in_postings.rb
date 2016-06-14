class RenameUnitKindColumnInPostings < ActiveRecord::Migration
  def change
    rename_column :postings, :unit_kind_id, :unit_id
  end
end
