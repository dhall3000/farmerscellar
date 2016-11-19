class RemovePaypalAcceptedColumnFromBusinessInterface < ActiveRecord::Migration[5.0]
  def change
    remove_column :business_interfaces, :paypal_accepted
  end
end