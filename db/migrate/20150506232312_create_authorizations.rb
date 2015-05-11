class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.text :response

      t.timestamps null: false
    end
  end
end
