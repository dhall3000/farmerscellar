class CreateUnitKinds < ActiveRecord::Migration
  def change
    create_table :unit_kinds do |t|
      t.string :name
      t.references :unit_category, index: true

      t.timestamps null: false
    end
    add_foreign_key :unit_kinds, :unit_categories
  end
end
