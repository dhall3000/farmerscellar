class CreatePaymentPayableToteItems < ActiveRecord::Migration
  def change
    create_table :payment_payable_tote_items, id: false do |t|
      t.references :tote_item, index: true
      t.references :payment_payable, index: true

      t.timestamps null: false
    end
    add_foreign_key :payment_payable_tote_items, :tote_items
    add_foreign_key :payment_payable_tote_items, :payment_payables
  end
end
