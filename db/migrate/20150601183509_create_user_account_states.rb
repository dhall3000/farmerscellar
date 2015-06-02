class CreateUserAccountStates < ActiveRecord::Migration
  def change
    create_table :user_account_states, id: false do |t|
      t.references :account_state, index: true
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_account_states, :account_states
    add_foreign_key :user_account_states, :users
  end
end
