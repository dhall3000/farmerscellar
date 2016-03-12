class ChangeFeeAmountNameOnPurchases < ActiveRecord::Migration
  def change
  	rename_column :purchases, :fee_amount, :payment_processor_fee_withheld_from_us
  end
end
