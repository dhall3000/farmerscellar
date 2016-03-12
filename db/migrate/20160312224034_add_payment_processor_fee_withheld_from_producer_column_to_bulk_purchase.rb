class AddPaymentProcessorFeeWithheldFromProducerColumnToBulkPurchase < ActiveRecord::Migration
  def change
  	add_column :bulk_purchases, :payment_processor_fee_withheld_from_producer, :float, default: 0
  end
end
