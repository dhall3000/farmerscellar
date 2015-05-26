class CreateCaptures < ActiveRecord::Migration
  def change
    create_table :captures do |t|
      t.float :amount

      t.timestamps null: false
    end
  end
end
