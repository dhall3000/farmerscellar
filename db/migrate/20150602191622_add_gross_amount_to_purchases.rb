class AddGrossAmountToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :gross_amount, :float
  end
end
