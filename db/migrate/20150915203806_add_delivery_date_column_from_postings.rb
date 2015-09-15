class AddDeliveryDateColumnFromPostings < ActiveRecord::Migration
  def change
    add_column :postings, :delivery_date, :datetime
  end
end
