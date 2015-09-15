class ChangeDeliveryDateColumnInPostings < ActiveRecord::Migration
  def change
  	change_column :postings, :delivery_date, :datetime
  end
end
