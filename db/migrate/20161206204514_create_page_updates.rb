class CreatePageUpdates < ActiveRecord::Migration[5.0]
  def change
    create_table :page_updates do |t|
      t.string :name
      t.datetime :update_time

      t.timestamps
    end
    add_index :page_updates, :name
  end
end