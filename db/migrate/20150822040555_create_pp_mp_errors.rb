class CreatePpMpErrors < ActiveRecord::Migration
  def change
    create_table :pp_mp_errors do |t|
      t.string :correlation_id
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
