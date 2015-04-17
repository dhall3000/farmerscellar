class AddFarmerApprovalToUsers < ActiveRecord::Migration
  def change
    add_column :users, :farmer_approval, :bool, default: false
  end
end
