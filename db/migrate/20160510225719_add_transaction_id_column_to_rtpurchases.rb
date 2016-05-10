class AddTransactionIdColumnToRtpurchases < ActiveRecord::Migration
  def change
    add_column :rtpurchases, :transaction_id, :string
  end
end
