class CreateFoodCategoryUploads < ActiveRecord::Migration[5.0]
  def change
    create_table :food_category_uploads do |t|
      t.references :food_category, foreign_key: true
      t.references :upload, foreign_key: true

      t.timestamps
    end
  end
end
