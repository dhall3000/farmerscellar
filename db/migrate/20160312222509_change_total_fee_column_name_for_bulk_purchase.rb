class ChangeTotalFeeColumnNameForBulkPurchase < ActiveRecord::Migration
  def change
  	rename_column :bulk_purchases, :total_fee, :payment_processor_fee_withheld_from_us
  end
end
