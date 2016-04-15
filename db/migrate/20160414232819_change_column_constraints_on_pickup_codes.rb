class ChangeColumnConstraintsOnPickupCodes < ActiveRecord::Migration
  def change
  	change_column :pickup_codes, :code, :string, null: false
  end
end
