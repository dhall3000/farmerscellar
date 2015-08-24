class CreatePpMpCommons < ActiveRecord::Migration
  def change
    create_table :pp_mp_commons do |t|
      t.string :correlation_id
      t.string :time_stamp
      t.string :ack
      t.string :version
      t.string :build

      t.timestamps null: false
    end
  end
end
