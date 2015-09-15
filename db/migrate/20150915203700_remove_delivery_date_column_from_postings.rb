class RemoveDeliveryDateColumnFromPostings < ActiveRecord::Migration
  def change
  	remove_column :postings, :delivery_date
  end
end
