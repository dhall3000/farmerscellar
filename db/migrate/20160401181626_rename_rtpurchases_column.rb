class RenameRtpurchasesColumn < ActiveRecord::Migration
  def change
  	rename_column :rtpurchases, :rtba_id, :ba_id
  end
end
