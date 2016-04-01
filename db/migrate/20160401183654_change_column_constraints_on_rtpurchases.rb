class ChangeColumnConstraintsOnRtpurchases < ActiveRecord::Migration
  def change
  	change_column :rtpurchases, :message, :string, null: false
  	change_column :rtpurchases, :correlation_id, :string, null: false
  end
end
