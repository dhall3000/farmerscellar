class AddColumnToPurchases < ActiveRecord::Migration
  def change
  	add_column :purchases, :payment_processor_fee_withheld_from_producer, :float, default: 0
  end
end
