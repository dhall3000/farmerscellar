class RenameErrorCodeColumnForRtpurchases < ActiveRecord::Migration
  def change
    rename_column :rtpurchases, :error_code, :error_codes
  end
end
