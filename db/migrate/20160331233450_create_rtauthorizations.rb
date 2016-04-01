class CreateRtauthorizations < ActiveRecord::Migration
  def change
    create_table :rtauthorizations do |t|
      t.references :rtba, index: true

      t.timestamps null: false
    end
    add_foreign_key :rtauthorizations, :rtbas
  end
end
