class CreateUserPurchaseReceivables < ActiveRecord::Migration
  def change
    create_table :user_purchase_receivables, id: false do |t|
      t.references :user, index: true
      t.references :purchase_receivable, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_purchase_receivables, :users
    add_foreign_key :user_purchase_receivables, :purchase_receivables
  end
end
