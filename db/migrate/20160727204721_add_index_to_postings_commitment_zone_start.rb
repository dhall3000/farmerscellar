class AddIndexToPostingsCommitmentZoneStart < ActiveRecord::Migration
  def change
    add_index :postings, :commitment_zone_start
  end
end
