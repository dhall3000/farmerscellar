class CreateGotIts < ActiveRecord::Migration[5.0]
  def change
    create_table :got_its do |t|
      t.references :user, foreign_key: true
      t.boolean :delivery_date_range_selection

      t.timestamps
    end
  end
end