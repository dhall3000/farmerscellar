class DropFarmerApprovalFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :farmer_approval
  end
end