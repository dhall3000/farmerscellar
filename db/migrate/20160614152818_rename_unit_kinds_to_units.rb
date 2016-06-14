class RenameUnitKindsToUnits < ActiveRecord::Migration
  def change
    rename_table :unit_kinds, :units
  end
end
