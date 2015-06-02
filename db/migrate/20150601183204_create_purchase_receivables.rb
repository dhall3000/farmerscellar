class CreatePurchaseReceivables < ActiveRecord::Migration
  def change
    create_table :purchase_receivables do |t|
      t.float :amount

      t.timestamps null: false
    end
  end
end
