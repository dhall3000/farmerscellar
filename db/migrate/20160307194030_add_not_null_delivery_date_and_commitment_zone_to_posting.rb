class AddNotNullDeliveryDateAndCommitmentZoneToPosting < ActiveRecord::Migration
  def change
  	change_column :postings, :delivery_date, :datetime, null: false
  	change_column :postings, :commitment_zone_start, :datetime, null: false
  end
end
