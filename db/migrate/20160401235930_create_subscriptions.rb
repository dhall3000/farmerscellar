class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :interval
      t.boolean :on
      t.references :user, index: true
      t.references :posting_recurrence, index: true

      t.timestamps null: false
    end
    add_foreign_key :subscriptions, :users
    add_foreign_key :subscriptions, :posting_recurrences
  end
end
