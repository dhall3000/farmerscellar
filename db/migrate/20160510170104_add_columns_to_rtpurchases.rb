class AddColumnsToRtpurchases < ActiveRecord::Migration
  def change
    add_column :rtpurchases, :payment_processor_fee_withheld_from_us, :float
    add_column :rtpurchases, :payment_processor_fee_withheld_from_producer, :float
  end
end
