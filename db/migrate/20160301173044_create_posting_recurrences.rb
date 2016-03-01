class CreatePostingRecurrences < ActiveRecord::Migration
  def change
    create_table :posting_recurrences do |t|
      t.integer :interval
      t.boolean :on

      t.timestamps null: false
    end
  end
end
