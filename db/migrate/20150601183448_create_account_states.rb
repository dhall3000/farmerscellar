class CreateAccountStates < ActiveRecord::Migration
  def change
    create_table :account_states do |t|
      t.integer :state
      t.text :description

      t.timestamps null: false
    end
  end
end
