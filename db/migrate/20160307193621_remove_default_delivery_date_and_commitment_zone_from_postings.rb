class RemoveDefaultDeliveryDateAndCommitmentZoneFromPostings < ActiveRecord::Migration
  def change
  	change_column_default :postings, :delivery_date, nil
  	change_column_default :postings, :commitment_zone_start, nil
  end
end
