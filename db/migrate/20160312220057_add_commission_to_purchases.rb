class AddCommissionToPurchases < ActiveRecord::Migration
  def change
  	add_column :purchases, :commission, :float, default: 0
  end
end
