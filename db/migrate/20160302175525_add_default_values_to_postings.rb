class AddDefaultValuesToPostings < ActiveRecord::Migration
  def change
  	change_column_default :postings, :quantity_available, 0
  	change_column_default :postings, :price, 0
  	change_column_default :postings, :live, false
  	change_column_default :postings, :delivery_date, Time.zone.yesterday
  	change_column_default :postings, :commitment_zone_start, Time.zone.yesterday - 1.day
  end
end
