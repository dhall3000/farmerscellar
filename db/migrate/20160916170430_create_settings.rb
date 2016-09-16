class CreateSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :settings do |t|
      t.references :user, foreign_key: true
      t.boolean :conditional_payment, default: false

      t.timestamps
    end
  end
end
