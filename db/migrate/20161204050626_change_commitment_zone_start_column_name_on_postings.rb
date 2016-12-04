class ChangeCommitmentZoneStartColumnNameOnPostings < ActiveRecord::Migration[5.0]
  def change
    rename_column :postings, :commitment_zone_start, :order_cutoff
  end
end