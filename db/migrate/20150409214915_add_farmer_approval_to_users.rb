class AddFarmerApprovalToUsers < ActiveRecord::Migration
  def change
    add_column :users, :farmer_approval, :boolean, default: false
  end
end
