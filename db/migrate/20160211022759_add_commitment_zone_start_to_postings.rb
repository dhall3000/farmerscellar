class AddCommitmentZoneStartToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :commitment_zone_start, :datetime
  end
end
