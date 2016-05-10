class RemoveFeeAmountFromRtpurchases < ActiveRecord::Migration
  def change
    remove_column :rtpurchases, :fee_amount
  end
end
